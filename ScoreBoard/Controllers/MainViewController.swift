//
//  ViewController.swift
//  ScoreBoard
//
//  Created by Василий Петухов on 27.12.2019.
//  Copyright © 2019 Vasily Petuhov. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textFieldTimer.font = NSFont.monospacedDigitSystemFont(ofSize: 30, weight: .regular) // настройка шрифта таймера (одинаковая ширина символа)
        
        //UserDefaults.standard.register(defaults: ["pathToUserDirectory" : FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!])
        //UserDefaults.standard.removeObject(forKey: "bookmarkForDirecory")
        
        writeFilesToDisk(.homeName, .awayName, .period, .homeGoal, .awayGoal)
        
        sliderTimer.integerValue = scoreBoardData.timeUserPreset // возвращаем состояние слайдера до закрытия проги
        showTimeInLabel() //при запуске выставляем таймер по умолчанию + пишем файл с таймером
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
        // MARK: - IBOutlet
    @IBOutlet weak var textFieldTimer: NSTextField!
    @IBOutlet weak var buttonStart: NSButton!
    @IBOutlet weak var switchTimerMode: NSSwitch!
    @IBOutlet weak var titleTimerMode: NSTextField!
    @IBOutlet weak var continueTimeSwitcher: NSSwitch!
    @IBOutlet weak var resetButton: NSButton!
    @IBOutlet weak var swapScores: NSButton!
    @IBOutlet weak var sliderTimer: NSSlider!
    @IBOutlet weak var textFieldHomeName: NSTextField!
    @IBOutlet weak var textFieldAwayName: NSTextField!
    @IBOutlet weak var goalHome: NSSegmentedControl!
    @IBOutlet weak var goalAway: NSSegmentedControl!
    @IBOutlet weak var period: NSSegmentedControl!
    @IBOutlet weak var stepperSeconds: NSStepper!
    @IBOutlet weak var stepperMinutes: NSStepper!
    
// параметры по умолчанию
//    var timeUserPreset: Int {
//        get {
//            UserDefaults.standard.register(defaults: ["timeUserPreset" : 900])
//            return UserDefaults.standard.integer(forKey: "timeUserPreset")
//        } set {
//            UserDefaults.standard.set(newValue, forKey: "timeUserPreset")
//        }
//    }
//    lazy var timeNow: Int = timeUserPreset
//    var homeName: String = "Home"
//    var awayName: String = "Away"
//    var countGoalHome: Int = 0
//    var countGoalAway: Int = 0
//    var periodCount: Int = 1
    
    var scoreBoardData = ScoreBoardData()
    
    // MARK: - FUNCtions
// newWrite сохранить закладку
    func saveBookmarksPathDirectory(_ userDirectoryUrl:URL) {
        
        // добавить название папки к пути выбранному пользователем
        //pathDirectory.url = userDirectoryUrl.appendingPathComponent("ScoreBoard Outputs")
        //guard let userDirectoryUrl = pathDirectory.url else { return }
        
        // сохраняем закладку безопасности на будущее
        do {
            let bookmark = try userDirectoryUrl.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmark, forKey: "bookmarkForDirecory")
            print("закладка сохранилась успешно: \(userDirectoryUrl)")
        } catch { return }
    }
    
// newWrite восстановить закладку
    func restoreBookmarksPathDirectory() -> URL? {
        guard let bookmark = UserDefaults.standard.data(forKey: "bookmarkForDirecory")
            else { return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first } // каталог downloads по умолчанию
        var bookmarkDataIsStale: ObjCBool = false
        
        do {
           let userDirectoryUrl = try (NSURL(resolvingBookmarkData: bookmark, options: [.withoutUI, .withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &bookmarkDataIsStale) as URL)
            
            if bookmarkDataIsStale.boolValue { return nil }
            
            guard userDirectoryUrl.startAccessingSecurityScopedResource() else { return nil }
            
            print("закладка открыта успешно: \(userDirectoryUrl)")
            return userDirectoryUrl
            
        } catch { return nil }
    }
    
// newWrite перечисление файлов для записи
    enum FilesToWrite {
        case timer, homeName, awayName, period, homeGoal, awayGoal
    }
    
// newWrite запись файлов
    func writeFilesToDisk(_ fileToWrite: FilesToWrite...) {
        do {
            if var userDirectoryUrl = restoreBookmarksPathDirectory() {
                userDirectoryUrl = userDirectoryUrl.appendingPathComponent("ScoreBoard Outputs")
                
                // проверка - существование каталога на диске
                if !FileManager().fileExists(atPath: userDirectoryUrl.path) {
                try FileManager.default.createDirectory(at: userDirectoryUrl, withIntermediateDirectories: true, attributes: nil)
                }
                
                var text: String
                var fileName: String
                
                for file in fileToWrite {
                    switch file {
                    case .timer:
                    text = textFieldTimer.stringValue
                    fileName = "Timer.txt"
                    case .homeName:
                        text = scoreBoardData.homeName
                       fileName = "Home_Name.txt"
                    case .awayName:
                       text = scoreBoardData.awayName
                       fileName = "Away_Name.txt"
                    case .period:
                       text = String(scoreBoardData.periodCount)
                       fileName = "Period.txt"
                    case .homeGoal:
                       text = String(scoreBoardData.countGoalHome)
                       fileName = "HomeGoal.txt"
                    case .awayGoal:
                       text = String(scoreBoardData.countGoalAway)
                       fileName = "AwayGoal.txt"
                   }
                    // запись нужного файла
                    try text.write(to: userDirectoryUrl.appendingPathComponent(fileName), atomically: false, encoding: .utf8)
                }
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Unable to write file"
            alert.informativeText = """
            There is no access to the directory for writing.
            Give the program access to write files to disk:

            System Preferences > Security and Privacy > Privacy > Files and Folders

            Check the box for the program "ScoreBoard.app".

            """
            alert.addButton(withTitle: "OK")
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
    
    
    // функция запоминает установленные параметры таймера из слайдера
    func setTimeDefault() {
        scoreBoardData.timeUserPreset = sliderTimer.integerValue
        if switchTimerMode.state == .on {
            //timeNow = sliderTimer.integerValue // зачем снова опрашивать слайдер? но так можно
            scoreBoardData.timeNow = scoreBoardData.timeUserPreset
        } else {
            scoreBoardData.timeNow = 0
        }
    }
    
    // функция показывает время в поле (берет из таймера)
    func showTimeInLabel() {
        
        stepperSeconds.integerValue = scoreBoardData.timeNow //сохраняет время для степперов
        stepperMinutes.integerValue = scoreBoardData.timeNow

        let minutes:Int = scoreBoardData.timeNow / 60
        let seconds:Int = scoreBoardData.timeNow - (minutes*60)
        var minStr:String = "\(minutes)"
        var secStr:String = "\(seconds)"
            
        // проверки МИНУТ и СЕКУНД на отсутсвие нулей (0:45 -> 01:45)
        if minutes < 10 {
            minStr = "0" + minStr
        }
        if seconds < 10 {
            secStr = "0" + secStr
        }
        textFieldTimer.stringValue = minStr + ":" + secStr //вывод времени в формате 00:00 в поле
        writeFilesToDisk(.timer) // это команда дублируется часто в других местах...
    }
    
    var timerStatus: Timer? //две функции для таймера (старт/стоп)
    func startTimer(){
      if timerStatus == nil {
            timerStatus = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
            (timer) in
                if self.switchTimerMode.state == .on {
                    guard self.scoreBoardData.timeNow > 0 else {
                        self.resetStateButtonStar()
                        return
                    }
                    self.scoreBoardData.timeNow -= 1
                } else {
                    guard self.scoreBoardData.timeNow < self.scoreBoardData.timeUserPreset else {
                        if self.continueTimeSwitcher.state == .on { self.scoreBoardData.timeUserPreset += self.scoreBoardData.timeUserPreset }
                        self.resetStateButtonStar()
                        return
                    }
                    self.scoreBoardData.timeNow += 1
                }
                self.showTimeInLabel()
            }
      }
    }
    
    func stopTimer(){
      if timerStatus != nil {
        timerStatus?.invalidate()
        timerStatus = nil
      }
    }
    
    // Сброс кнопки СТАРТ на начальное значение + остановка таймера
    func resetStateButtonStar(){
        stopTimer()
        buttonStart.title = "START"
        textFieldTimer.textColor = .black
    }
    
    // Сброс всех параметров проги на умолчание
    func resetAllState(){
        resetStateButtonStar()
        setTimeDefault()
        showTimeInLabel()
//        homeName = "Home"
//        textFieldHomeName.stringValue = homeName
//        awayName = "Away"
//        textFieldAwayName.stringValue = awayName
        scoreBoardData.countGoalHome = 0
        goalHome.setLabel(String(scoreBoardData.countGoalHome), forSegment: 1)
        scoreBoardData.countGoalAway = 0
        goalAway.setLabel(String(scoreBoardData.countGoalAway), forSegment: 1)
        scoreBoardData.periodCount = 1
        period.setLabel(String(scoreBoardData.periodCount), forSegment: 1)
        writeFilesToDisk(.homeName, .awayName, .period, .homeGoal, .awayGoal)
    }
    
    // MARK: - ACTIONS
    
    @IBAction func timeLabelAction(_ sender: Any) {
        var timeFromUserInLabel = Array (textFieldTimer.stringValue.components(separatedBy:CharacterSet.decimalDigits.inverted)
            .joined()) //убирает все кроме цифр
        
        //надо сразу чистить массив чтобы не было лишнего .map .sort и тд
        
        // запоминает время до изменения
        var minutesFromUser:Int = scoreBoardData.timeNow / 60
        var secondsFromUser:Int = scoreBoardData.timeNow - ((scoreBoardData.timeNow / 60) * 60)
        
        
        if timeFromUserInLabel.count < 3 { //проверка на количество цифр, не меннее 3-ех (минуты:секунды), иначе ,будет краш проги
        showTimeInLabel()
        }
        if timeFromUserInLabel.count >= 4 { // если пользователь ввел 4 или больше знаков
            minutesFromUser = Int (String (timeFromUserInLabel [0...1]))!
            secondsFromUser = Int (String (timeFromUserInLabel [2...3]))!
        }
        if timeFromUserInLabel.count == 3 { // если пользователь ввел 3 знака
            timeFromUserInLabel.insert("0", at: 0)
            minutesFromUser = Int (String (timeFromUserInLabel [0...1]))!
            secondsFromUser = Int (String (timeFromUserInLabel [2...3]))!
        }
        scoreBoardData.timeNow = (minutesFromUser * 60) + secondsFromUser
        showTimeInLabel()
    }
    
    @IBAction func stepperSecondsAction(_ sender: Any) {
        scoreBoardData.timeNow = stepperSeconds.integerValue
        showTimeInLabel()
    }
    
    
    @IBAction func stepperMinutesAction(_ sender: Any) {
        scoreBoardData.timeNow = stepperMinutes.integerValue
        showTimeInLabel()
    }
    
    @IBAction func goalHomeAction(_ sender: Any) {
        if goalHome.selectedSegment == 0, scoreBoardData.countGoalHome > 0 {
            scoreBoardData.countGoalHome -= 1
        }
        if goalHome.selectedSegment == 2 || goalHome.selectedSegment == -1 { // -1 когда передается действие из меню (не нажатие)
            scoreBoardData.countGoalHome += 1
        }
        goalHome.setLabel(String(scoreBoardData.countGoalHome), forSegment: 1)
        writeFilesToDisk(.homeGoal)
    }
    
    @IBAction func goalAwayAction(_ sender: Any) {
        if goalAway.selectedSegment == 0, scoreBoardData.countGoalAway > 0 {
            scoreBoardData.countGoalAway -= 1
        }
        if goalAway.selectedSegment == 2  || goalAway.selectedSegment == -1 {
            scoreBoardData.countGoalAway += 1
        }
        goalAway.setLabel(String(scoreBoardData.countGoalAway), forSegment: 1)
        writeFilesToDisk(.awayGoal)
    }
    
    @IBAction func periodAction(_ sender: Any) {
        if period.selectedSegment == 0, scoreBoardData.periodCount > 1 {
            scoreBoardData.periodCount -= 1
        }
        if period.selectedSegment == 2  || period.selectedSegment == -1 {
            scoreBoardData.periodCount += 1
        }
        period.setLabel(String(scoreBoardData.periodCount), forSegment: 1)
        writeFilesToDisk(.period)
    }
    
    @IBAction func textFieldHomeNameAction(_ sender: Any) {
        scoreBoardData.homeName = textFieldHomeName.stringValue
        writeFilesToDisk(.homeName)
    }
    
    @IBAction func textFieldAwayNameAction(_ sender: Any) {
        scoreBoardData.awayName = textFieldAwayName.stringValue
        writeFilesToDisk(.awayName)
    }
    
    @IBAction func sliderTimerAction(_ sender: Any) {
        setTimeDefault()
        showTimeInLabel()
    }
    
    @IBAction func pushButtonStart(_ sender: Any) {
        //sliderTimer.isEnabled = false
        if timerStatus == nil {
            buttonStart.title = "PAUSE"
            textFieldTimer.textColor = .red
            startTimer()
        } else {
            resetStateButtonStar()
        }
    }
    
    @IBAction func switchTimerOnOff(_ sender: Any) {
        if switchTimerMode.state == .on {
            titleTimerMode.stringValue = "Countdown: ON"
            continueTimeSwitcher.state = .off
            continueTimeSwitcher.isEnabled = false
        } else {
            titleTimerMode.stringValue = "Countdown: OFF"
            continueTimeSwitcher.isEnabled = true
        }
        scoreBoardData.timeNow = scoreBoardData.timeUserPreset - scoreBoardData.timeNow  // смена времени на табло с сохранением пройденных секунд
        showTimeInLabel()
    }
    
    @IBAction func resetButtonPush(_ sender: Any) {
        resetAllState()
    }
    
    @IBAction func swapHomeAwayScores(_ sender: Any) {
        swap(&scoreBoardData.homeName, &scoreBoardData.awayName)
        textFieldHomeName.stringValue = scoreBoardData.homeName
        textFieldAwayName.stringValue = scoreBoardData.awayName
        swap(&scoreBoardData.countGoalHome, &scoreBoardData.countGoalAway)
        goalHome.setLabel(String(scoreBoardData.countGoalHome), forSegment: 1)
        goalAway.setLabel(String(scoreBoardData.countGoalAway), forSegment: 1)
        writeFilesToDisk(.homeName, .awayName, .homeGoal, .awayGoal)
    }
    
// MARK:- Menu action
    
    @IBAction func startPauseTimerFromMenu(_ sender: Any) {
        pushButtonStart(self)
    }
    
    @IBAction func plus1SecFromMenu(_ sender: Any) {
        scoreBoardData.timeNow += 1
        showTimeInLabel()
    }
    
    @IBAction func minus1SecFromMenu(_ sender: Any) {
        guard scoreBoardData.timeNow > 0 else { return }
        scoreBoardData.timeNow -= 1
        showTimeInLabel()
    }
    
    @IBAction func plus1MinFromMenu(_ sender: Any) {
        scoreBoardData.timeNow += 60
        showTimeInLabel()
        //stepperMinutesAction.()
    }
    
    @IBAction func minus1MinFromMenu(_ sender: Any) {
        guard scoreBoardData.timeNow > 60 else { return }
        scoreBoardData.timeNow -= 60
        showTimeInLabel()
    }
    
    @IBAction func resetAllStateFromMenu(_ sender: Any) {
        resetButtonPush(self)
    }
    
    @IBAction func plus1GoalHomeFromMenu(_ sender: Any) {
        goalHomeAction(self)
    }
    
    @IBAction func plus1GoalAwayFromMenu(_ sender: Any) {
        goalAwayAction(self)
    }
    
    @IBAction func plus1PeriodFromMenu(_ sender: Any) {
        periodAction(self)
    }
    

}
