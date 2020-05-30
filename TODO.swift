/*
 
//MARK: - Code
 
 TODO: appendingPathComponent should always have the isDirectory flag given to avoid superfluous disk access
 TODO: Be careful with Calendar.gregorian/Calendar.current and firstWeekday = 2
 TODO: Replace pickers with pop-up tableViews
 TODO: IF this is imperformant: orderedActivities can be replaced by https://github.com/lukaskubanek/OrderedDictionary
 
//MARK: - Plotting
 TODO: Input time range: Default: Last 7 days. Default buttons (last (1-3) weeks, this week), last (1, 2, 3, 6) months, this month, this year. Click on date: Manually select date range with DateView (split ranges?). Sum up weeks in month view, months in year view. Compare last week with current week.
 TODO: 2 Plots gleichzeitig (z. B. zum Vergleichen von letzter Woche mit vorletzter Woche, Titel zeigt prozentuale Änderung)
 TODO: Input sources: Symbol for each measurement method, can't mix up methods except: Combined line/bar chart for Time, Float and Int. Combined chart: Combined checkbutton, tap once on first, once on second activity
 TODO: Plot type: Line/Bar/Pie for all 3 options. Pie: 1. Select method 2. Select activities. Line/Bar: Only 1 activity at a time
 
//MARK: - Explorer
 TODO: copy photos/videos to/select from camera roll
 TODO: Timer.startDate and self.chosenDate concurrency: Add value of end-start to today's value or make a cut at 23:59:59 (appdelegate significant time change)
 TODO: Search bar
 TODO: Receive attachments from other applications (Voice memo, photo library) via "Copy to/Open in Rival"
 TODO: Notify to input data with alert
 TODO: Goals for every activity, green dot for fulfilled goal in calendar
 
//MARK: - Ad
 
 Right side - (animated) Plot, use of the app.
 Left side - Video respective to every sentence.
 This is how long it takes me and my friends to run our standard routes. (Tim is doing it, I'm talking to a pretty girl). Tim is improving, I'm too constant. (Tim falls down on the ground and barely manages to press stop before passing out.) I should try to get faster.
 This is how long me and my sister brush our teeth in the morning and at night. I'm barely scratching the minimum in the morning, but at least I'm better than my sister. She will ask strangers to start her apple in no time. (Fade out while strange woman bites into an apple and looks in the camera, wondering if this is a joke)
 This is how much I spent on groceries this week. I spend way too much on weekends. I should cut down on that.
 This is how many time I mastur-
 Ahem. This is Rival. It's a cool App. You should get it.
 
//MARK: - Networking
 
 TODO: Groups for rivalizing with friends
 
 */

/*
 Template:
 
//MARK: - Types
 
 
 
//MARK: - Properties
 
 

//MARK: - Initialization
 
 
 
//MARK: - Public Methods
 
 
 
//MARK: - Private Methods
 
 
 
//MARK: - Actions
 


//MARK: - Navigation
 
 
 
//MARK: - Delegates
 */

//AVPlayer (Video) and AVAudioPlayer (Audio) take URLS instead of Bytestreams. I'm not sure if its feasible to load whole videos to the ram just to avoid reloading them. For now, everything is loaded live from the disk. For Audio and Video, named pipes would be the way to go: https://stackoverflow.com/questions/48229690/how-to-open-data-instead-standart-url-in-avplayer
/*
 func setupNamedPipe(withData data: Data) -> URL?
 {
     // Build a URL for a named pipe in the documents directory
     let fifoBaseName = "avpipe"
     let fifoUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!.appendingPathComponent(fifoBaseName)

     // Ensure there aren't any remnants of the fifo from a previous run
     unlink(fifoUrl.path)

     // Create the FIFO pipe
     if mkfifo(fifoUrl.path, 0o666) != 0
     {
         print("Failed to create named pipe")
         return nil
     }

     // Run the code to manage the pipe on a dispatch queue
     DispatchQueue.global().async
     {
         print("Waiting for somebody to read...")
         let fd = open(fifoUrl.path, O_WRONLY)
         if fd != -1
         {
             print("Somebody is trying to read, writing data on the pipe")
             data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
                 let num = write(fd, bytes, data.count)
                 if num != data.count
                 {
                     print("Write error")
                 }
             }

             print("Closing the write side of the pipe")
             close(fd)
         }
         else
         {
             print("Failed to open named pipe for write")
         }

         print("Cleaning up the named pipe")
         unlink(fifoUrl.path)
     }

     return fifoUrl
 }
 */
