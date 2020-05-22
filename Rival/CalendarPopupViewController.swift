//
//  ViewController.swift
//  CalendarTest
//
//  Created by Yannik Schroeder on 08.05.20.
//  Copyright © 2020 Yannik Schroeder. All rights reserved.
//

import UIKit
import JTAppleCalendar

class DateHeader: JTACMonthReusableView {
    @IBOutlet weak var monthTitle: UILabel!
    @IBOutlet weak var weekNames: UIStackView!
}

class DateCell: JTACDayCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var selectedView: UIView!
    @IBOutlet weak var dotView: UIView!
}

class CalendarViewController: UIViewController {
    
    //MARK: - Types
    
    enum Mode {
        case singleSelection
        case rangeSelection
    }
    
    //MARK: - Properties

    @IBOutlet weak var calendar: JTACMonthView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    ///The month of this date represents the month currently viewed
    var currentDate = Date().startOfMonth
    var firstDate: Date? = nil
    var secondDate: Date? = nil
    let startDate = DateFormats.full.date(from: "01.01.2019")!
    let endDate = DateFormats.full.date(from: "01.01.2021")!
    var singleSelectionCallback: ((Date) -> Void)!
    var rangeSelectionCallback: ((Date, Date) -> Void)!
    var selectionMode: Mode = .singleSelection
    var todayButtonPressed = false
    var activity: Activity?
    
    
    //MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        calendar.calendarDelegate = self
        calendar.calendarDataSource = self
        tableView.delegate = self
        tableView.dataSource = self
        Calendar.iso.locale = Locale(identifier: "de_DE")
        Calendar.iso.firstWeekday = 2
        if self.selectionMode == .rangeSelection {
            calendar.allowsRangedSelection = true
            calendar.allowsMultipleSelection = true
        }
        if let date = self.firstDate, secondDate == nil {
            self.currentDate = date.startOfMonth
            calendar.selectDates([date])
        }
        else if firstDate != nil && secondDate != nil {
            self.currentDate = firstDate!.startOfMonth
            calendar.selectDates(from: firstDate!, to: secondDate!, triggerSelectionDelegate: true, keepSelectionIfMultiSelectionAllowed: true)
        }
        scroll()
    }
    
    //MARK: - Actions
    
    @IBAction func previousMonthChosen(_ sender: UIButton?) {
        if Calendar.iso.isDate(currentDate, equalTo: startDate, toGranularity: .month) {
            return
        }
        currentDate = Calendar.iso.date(byAdding: .month, value: -1, to: currentDate)!
        scroll()
    }
    
    @IBAction func nextMonthChosen(_ sender: UIButton?) {
        if Calendar.iso.isDate(currentDate, equalTo: endDate, toGranularity: .month) {
            return
        }
        currentDate = Calendar.iso.date(byAdding: .month, value: 1, to: currentDate)!
        scroll()
    }
    
    @IBAction func todayChosen(_ sender: UIBarButtonItem) {
        todayButtonPressed = true
        currentDate = Date()
        calendar.selectDates([currentDate])
        scroll()
    }
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Private Methods
    
    private func scroll(animated: Bool = false) {
        calendar.scrollToDate(currentDate, triggerScrollToDateDelegate: false, animateScroll: animated, preferredScrollPosition: nil, extraAddedOffset: 0, completionHandler: nil)
    }
    
    private func configureCell(view: JTACDayCell?, cellState: CellState) {
        guard let cell = view as? DateCell else {
            return
        }
        cell.dotView.backgroundColor = UIColor.clear
        if let activity = activity {
            if activity[cellState.date].measurement != 0 {
                cell.dotView.backgroundColor = UIColor.systemGray3
                cell.dotView.layer.cornerRadius = 5
            }
        }
        cell.dateLabel.text = cellState.text
        handleCellTextColor(cell: cell, cellState: cellState)
        handleCellSelected(cell: cell, cellState: cellState)
    }
    
    private func handleCellTextColor(cell: DateCell, cellState: CellState) {
        if cellState.dateBelongsTo == .thisMonth {
            cell.dateLabel.textColor = UIColor.black
        }
        else {
            cell.dateLabel.textColor = UIColor.gray
        }
    }
    
    private func handleCellSelected(cell: DateCell, cellState: CellState) {
        let isFirstOrSecond: Bool
        if let first = firstDate, first == cellState.date {
            isFirstOrSecond = true
        }
        else if let second = secondDate, second == cellState.date {
            isFirstOrSecond = true
        }
        else {
            isFirstOrSecond = false
        }
        
        if cellState.isSelected || (isFirstOrSecond && self.selectionMode == .rangeSelection) {
            cell.selectedView.backgroundColor = UIColor.blue
        }
        else {
            cell.selectedView.backgroundColor = UIColor.clear
        }
    }
}

//MARK: - Extensions

extension CalendarViewController: JTACMonthViewDataSource {
    func configureCalendar(_ calendar: JTACMonthView) -> ConfigurationParameters {
        return ConfigurationParameters(startDate: startDate,
        endDate: endDate,
        calendar: Calendar.iso,
        generateInDates: .forAllMonths,
        generateOutDates: .tillEndOfRow)
    }
}

extension CalendarViewController: JTACMonthViewDelegate {
    func calendar(_ calendar: JTACMonthView, headerViewForDateRange range: (start: Date, end: Date), at indexPath: IndexPath) -> JTACMonthReusableView {
        let header = calendar.dequeueReusableJTAppleSupplementaryView(withReuseIdentifier: "DateHeader", for: indexPath) as! DateHeader
        header.monthTitle.text = DateFormats.monthYear.string(from: range.start)
        header.weekNames.subviews.forEach({$0.removeFromSuperview()})
        for i in 0...6 {
            let label = UILabel()
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 12)
            var index = i+1
            if index > 6 {
                index = 0
            }
            label.text = Calendar.iso.weekdaySymbols[index].prefix(2) + "."
            header.weekNames.addArrangedSubview(label)
        }
        return header
    }
    
    func calendarSizeForMonths(_ calendar: JTACMonthView?) -> MonthSize? {
        return MonthSize(defaultSize: 60)
    }
    
    func calendar(_ calendar: JTACMonthView, didSelectDate date: Date, cell: JTACDayCell?, cellState: CellState, indexPath: IndexPath) {
        switch(self.selectionMode) {
        case .singleSelection:
            self.firstDate = date
            singleSelectionCallback(date)
        case .rangeSelection:
            if self.firstDate == nil {
                self.firstDate = date
            }
            else if self.secondDate == nil && cellState.date != firstDate! {
                self.secondDate = date
                if secondDate! < firstDate! {
                    swap(&firstDate, &secondDate)
                }
                calendar.selectDates(from: firstDate!, to: secondDate!, triggerSelectionDelegate: true, keepSelectionIfMultiSelectionAllowed: true)
                rangeSelectionCallback(firstDate!, secondDate!)
            }
            else {
                if cellState.selectionType! == .userInitiated || todayButtonPressed {
                    todayButtonPressed = false
                    firstDate = cellState.date
                    secondDate = nil
                    calendar.deselectAllDates()
                }
            }
        }
        configureCell(view: cell, cellState: cellState)
        if cellState.selectionType! == .userInitiated {
            if !Calendar.iso.isDate(date, equalTo: currentDate, toGranularity: .month) {
                if date > currentDate {
                    nextMonthChosen(nil)
                }
                else {
                    previousMonthChosen(nil)
                }
            }
        }
    }
    
    func calendar(_ calendar: JTACMonthView, didDeselectDate date: Date, cell: JTACDayCell?, cellState: CellState, indexPath: IndexPath) {
        switch(self.selectionMode) {
        case .rangeSelection:
            if cellState.selectionType! == .userInitiated || todayButtonPressed {
                todayButtonPressed = false
                firstDate = nil
                secondDate = nil
                calendar.deselectAllDates()
                calendar.selectDates([cellState.date])
            }
            else {
                configureCell(view: cell, cellState: cellState)
            }
        case .singleSelection:
            configureCell(view: cell, cellState: cellState)
        }
    }
    
    func calendar(_ calendar: JTACMonthView, willDisplay cell: JTACDayCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        configureCell(view: cell, cellState: cellState)
    }
    
    func calendar(_ calendar: JTACMonthView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTACDayCell {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "dateCell", for: indexPath) as! DateCell
        self.calendar(calendar, willDisplay: cell, forItemAt: date, cellState: cellState, indexPath: indexPath)
        cell.layer.borderWidth = 0.5
        cell.layer.borderColor = UIColor.black.cgColor
        if cellState.date.isToday() {
            cell.layer.backgroundColor = UIColor.gray.cgColor
        }
        else {
            cell.layer.backgroundColor = UIColor.clear.cgColor
        }
        return cell
    }
}

extension CalendarViewController: UITableViewDelegate {
    
}

extension CalendarViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        return cell
    }
}
