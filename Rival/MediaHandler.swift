//
//  MediaStore.swift
//  Rival
//
//  Created by Yannik Schroeder on 27.05.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import AVFoundation
import MobileCoreServices

class MetaData: Codable {
    var name: String
    var date: Date
    let id: UUID
    
    init(name: String, date: Date) {
        self.name = name
        self.date = date
        id = UUID()
    }
}

//Activities are stored to /act/uuidString. Media files are stored to /act/uuidString_data/date.dateString(). Meta data is stored to /act/uuidString_data/date.dateString()_meta.

enum MediaError: Error {
    case RecordAudioError(String)
    case PlayAudioError(String)
    case RecordPhotoError(String)
    case SeePhotoError(String)
    case RecordVideoError(String)
    case WatchVideoError(String)
}

protocol ErrorDelegate: UIViewController {
    func presentError(_ error: Error)
}

protocol MediaDelegate: ErrorDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
}

class MediaHandler {
    
    //MARK: - Properties
    
    static let shared = MediaHandler()
    var delegate: MediaDelegate?
    var recordButton: UIButton?
    var playButton: UIButton?
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var activity: Activity?
    var date: Date? {
        didSet {
            updateButtonTexts()
        }
    }
    var mode: AttachmentType = .none //Used to determine the file extension
    var fileExtension: String {
        switch(mode) {
        case .audio:
            return "m4a"
        case .photo:
            return "jpg"
        case .video:
            return "mov"
        case .none:
            return ""
        }
    }
    var mediaURL: URL! {
        if let activity = activity, let date = date {
            return getMediaArchiveURL(for: activity, at: date)
        }
        return nil
    }
    var recorded: Bool {
        return manager.fileExists(atPath: mediaURL?.path ?? "")
    }
    let manager = FileManager.default
    var image: UIImage? {
        if let data = try? Data(contentsOf: mediaURL) {
            return UIImage(data: data)
        }
        return nil
    }
    
    //MARK: - Initialization
    
    init() {
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playback, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { allowed in
                DispatchQueue.main.async {
                    if !allowed {
                        self.delegate?.presentError(MediaError.RecordAudioError("Keine Rechte für Mikrofonzugriff. Die Rechte können Sie unter Systemeinstellungen - Rival ändern."))
                    }
                }
            }
            self.recordingSession = recordingSession
        }
        catch {
            delegate?.presentError(MediaError.RecordAudioError("Unbekannter Fehler: \(error.localizedDescription)"))
        }
    }
    
    //MARK: - Audio
    
    func assignAudioButtons(recordButton: UIButton, playButton: UIButton) {
        recordButton.addTarget(self, action: #selector(recordAudioButtonTapped), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(playAudioButtonTapped), for: .touchUpInside)
        self.recordButton = recordButton
        self.playButton = playButton
        mode = .audio
        updateButtonTexts()
    }
    
    @objc private func recordAudioButtonTapped() {
        if audioRecorder == nil {
            startRecording()
        }
        else {
            finishRecording(success: true)
        }
    }
    
    @objc private func playAudioButtonTapped() {
        guard !(audioRecorder?.isRecording ?? false) else {
            delegate?.presentError(MediaError.PlayAudioError("Es wird gerade aufgenommen."))
            return
        }
        //Doing this instead of .recordAndPlay solved a volume issue on my device
        try! recordingSession.setCategory(.playback)
        
        let playerController = AVPlayerViewController()
        let player = AVPlayer(url: mediaURL)
        playerController.player = player
        delegate?.present(playerController, animated: true) {
            player.play()
        }
    }
    
    private func startRecording() {
        guard !(audioPlayer?.isPlaying ?? false) else {
            delegate?.presentError(MediaError.RecordAudioError("Die Datei kann nicht geändert werden, da sie gerade abgespielt wird."))
            return
        }
        audioPlayer = nil
        try! recordingSession.setCategory(.record)
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: mediaURL, settings: settings)
            audioRecorder.delegate = delegate
            audioRecorder.record()
        }
        catch {
            finishRecording(success: false)
        }
        updateButtonTexts()
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        updateButtonTexts()
        try! recordingSession.setCategory(.playback)
    }
    
    //MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        updateButtonTexts()
    }
    
    //MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
        updateButtonTexts()
    }
    
    //MARK: - Photo
    
    func assignPhotoButtons(recordButton: UIButton, seeButton: UIButton) {
        recordButton.addTarget(self, action: #selector(recordPhotoTapped), for: .touchUpInside)
        //seeButton.addTarget(self, action: #selector(seePhotoTapped), for: .touchUpInside)
        self.recordButton = recordButton
        self.playButton = seeButton
        mode = .photo
        updateButtonTexts()
    }
    
    @objc func recordPhotoTapped() {
        let imagePicker = UIImagePickerController()
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            delegate?.presentError(MediaError.RecordPhotoError("Das Gerät hat keine Kamera."))
        }
        imagePicker.delegate = delegate
        imagePicker.sourceType = .camera
        delegate?.present(imagePicker, animated: true, completion: nil)
    }
    
    //MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            let data = image.jpegData(compressionQuality: 1)!
            try! data.write(to: mediaURL)
        }
        else if let movieURL = info[.mediaURL] as? URL {
            if FileManager.default.fileExists(atPath: mediaURL.path) {
                try! FileManager.default.removeItem(at: mediaURL)
            }
            try! FileManager.default.copyItem(at: movieURL, to: mediaURL)
        }
        print("Media size: \(((try? manager.attributesOfItem(atPath: mediaURL.path))?[.size] as? Double ?? 0) / 1024.0 / 1024.0) MiB")
        delegate?.dismiss(animated: true, completion: nil)
        updateButtonTexts()
    }
    
    //MARK: - Video
    
    func assignVideoButtons(recordButton: UIButton, watchButton: UIButton) {
        recordButton.addTarget(self, action: #selector(recordVideoTapped), for: .touchUpInside)
        watchButton.addTarget(self, action: #selector(watchVideoTapped), for: .touchUpInside)
        self.recordButton = recordButton
        playButton = watchButton
        mode = .video
        updateButtonTexts()
    }
    
    @objc func recordVideoTapped() {
        let imagePicker = UIImagePickerController()
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            delegate?.presentError(MediaError.RecordPhotoError("Das Gerät hat keine Kamera."))
        }
        imagePicker.sourceType = .camera
        //Order is important here, do this before assigning the delegate
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        if !(UIImagePickerController.availableMediaTypes(for: .camera)?.contains(kUTTypeMovie as String) ?? false) {
            delegate?.presentError(MediaError.RecordVideoError("Dieses Gerät kann keine Videos aufnehmen."))
        }
        imagePicker.delegate = delegate
        imagePicker.cameraCaptureMode = .video
        imagePicker.videoQuality = .type640x480
        imagePicker.videoMaximumDuration = 10
        delegate?.present(imagePicker, animated: true, completion: nil)
    }
    
    @objc func watchVideoTapped() {
        let player = AVPlayer(url: mediaURL!)
        let playerController = AVPlayerViewController()
        
        playerController.player = player
        delegate?.present(playerController, animated: true) {
            player.play()
        }
    }
    
    //MARK: - General
    
    private func updateButtonTexts() {
        let recorded = self.recorded
        if mode == .audio {
            if let player = audioPlayer, player.isPlaying {
                recordButton?.disable()
                playButton?.setTitle("Stoppen", for: .normal)
                return
            }
            if let recorder = audioRecorder, recorder.isRecording {
                playButton?.disable()
                recordButton?.setTitle("Stoppen", for: .normal)
                return
            }
            recordButton?.enable()
            playButton?.setTitle("Abspielen", for: .normal)
        }
        if recorded {
            playButton?.enable()
            recordButton?.setTitle("Neu aufnehmen", for: .normal)
        }
        else {
            playButton?.disable()
            recordButton?.setTitle("Aufnehmen", for: .normal)
        }
    }
    
    func getMetaArchiveURL(for activity: Activity, at date: Date) -> URL {
        return Filesystem.shared.activitiesArchiveURL.appendingPathComponent(activity.id.uuidString+"_data", isDirectory: true).appendingPathComponent(date.dateString()+"_meta", isDirectory: false)
    }
    
    func getMediaArchiveURL(for activity: Activity, at date: Date? = nil) -> URL {
        if let date = date {
            return Filesystem.shared.activitiesArchiveURL.appendingPathComponent(activity.id.uuidString+"_data", isDirectory: true).appendingPathComponent(date.dateString(), isDirectory: false).appendingPathExtension(fileExtension)
        }
        return Filesystem.shared.activitiesArchiveURL.appendingPathComponent(activity.id.uuidString+"_data", isDirectory: true)
    }
}
