import SwiftUI
import EventKit
import Foundation

struct WeekdayHeaderView: View {
    let weekdays = [NSLocalizedString("Monday", comment: ""),
                    NSLocalizedString("Tuesday", comment: ""),
                    NSLocalizedString("Wednesday", comment: ""),
                    NSLocalizedString("Thursday", comment: ""),
                    NSLocalizedString("Friday", comment: ""),
                    NSLocalizedString("Saturday", comment: ""),
                    NSLocalizedString("Sunday", comment: "")]
    
    @Binding var isMenuOpen: Bool
    @Binding var isDayOpen: Bool
    @Binding var hideSettingsIcons: Bool
    
    var body: some View {
        ZStack {
            HStack {
                if !hideSettingsIcons {
                    Button(action: {
                        isMenuOpen.toggle()
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                    }
                }
                Spacer()
                
                Button(action: {
                    isDayOpen.toggle()
                }) {
                    Image(systemName: "clock")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                }
            } // HStack
            .frame(maxWidth: .infinity)
            
            ZStack {
                HStack {
                    ForEach(weekdays, id: \.self) { weekday in
                        Text(weekday)
                            .font(.headline)
                            .textCase(.uppercase)
                        //.padding(.horizontal, 5)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.clear)
                .foregroundColor(Color(UIColor.systemGray))
                .padding()
            }
            .frame(maxWidth: .infinity)
            .padding(0)
            .background(Color.clear)
        }
    }
}

class EventStoreHelper {
    static func getAllCalendars() -> [String] {
        let eventStore = EKEventStore()
        var calendarNames: [String] = []
        
        if EKEventStore.authorizationStatus(for: .event) == .authorized {
            let calendars = eventStore.calendars(for: .event)
            calendarNames = calendars.map { $0.title }
        }
        
        return calendarNames
    }
}

class DailyTaskData: ObservableObject {

    @Published var dailyTasks: Set<String>
    @Published var taskCalendar: String {
            didSet {
                objectWillChange.send()
                saveDailyTasks()
            }
        }
    
    init() {
        self.taskCalendar = "Hem"
        
        if let taskCalendarFromUserDefaults = UserDefaults.standard.stringArray(forKey: "taskCalendar") {
            taskCalendar = taskCalendarFromUserDefaults.first ?? "Hem"
            print("taskCalendarFromUserDefaults: ", taskCalendarFromUserDefaults)
        } else {
            let tasksForDate = MyTasks.fetchTasksForDate()
            let calendarNames = tasksForDate.map { $0.calendarName }
            print("501")
            taskCalendar = calendarNames.first ?? "Hem"
        }
        
        self.dailyTasks = Set(EventStoreHelper.getAllCalendars())
    }
    
    func saveDailyTasks() {
         print("save taskCalendar: ", taskCalendar)
        let taskArray = Array(dailyTasks)
        let taskCalendarSave = self.taskCalendar
        UserDefaults.standard.set(taskArray, forKey: "dailyTasks")
        UserDefaults.standard.set(taskCalendarSave, forKey: "taskCalendar")
        let dataChecking = UserDefaults.standard.stringArray(forKey: "taskCalendar")
        print("dataChecking: ", dataChecking as Any)
    }
}

// Putting this one that works ok here, in case I make it worse. This does not save though.
//class DailyTaskData: ObservableObject {
//    var selectedTaskCalendar: [String] {
//        didSet {
//            saveDailyTasks()
//        }
//    }
//    @Published var dailyTasks: Set<String> {
//        didSet {
//            saveDailyTasks()
//        }
//    }
//
//// Nested myself in so many bindings and vars so I lost the save,
//// I'm dropping this for now to not make it worse... Got to fix later.
//// Right now updates get into selectedTaskCalendar but dailyTasks keeps
//// the full array and are the published one...
//
//    init() {
//        if EKEventStore.authorizationStatus(for: .event) == .authorized {
//            let tasksForDate = MyTasks.fetchTasksForDate()
//            let calendarNames = tasksForDate.map { $0.calendarName }
//            selectedTaskCalendar = calendarNames
//        } else {
//            selectedTaskCalendar = []
//        }
//
//        if let taskCalendarFromUserDefaults = UserDefaults.standard.string(forKey: "selectedTaskCalendar") {
//            selectedTaskCalendar = [taskCalendarFromUserDefaults]
//        }
//
//        self.dailyTasks = Set(selectedTaskCalendar)
//    }
//
//    private func saveDailyTasks() {
//        let taskArray = Array(dailyTasks)
//        UserDefaults.standard.set(taskArray, forKey: "dailyTasks")
//        UserDefaults.standard.set(selectedTaskCalendar, forKey: "selectedTaskCalendar")
//    }
//}

class CalendarData: ObservableObject {
    @Published var selectedCalendars: Set<String> {
        didSet {
            saveSelectedCalendars()
        }
    }
    
    init() {
        if let savedCalendars = UserDefaults.standard.stringArray(forKey: "selectedCalendars") {
            self.selectedCalendars = Set(savedCalendars)
        } else {
            self.selectedCalendars = Set(["Hem"])
        }
    }
    
    private func saveSelectedCalendars() {
        let calendarArray = Array(selectedCalendars)
        UserDefaults.standard.set(calendarArray, forKey: "selectedCalendars")
    }
}

struct CalendarMenuView: View {
    @Binding var eventsForDay: [EventInfo]
    @Binding var isOpen: Bool
    @Binding var selectedCalendars: Set<String>
    @ObservedObject var calendarData: CalendarData
    
    var body: some View {
        VStack {
            Button(action: {
                isOpen.toggle()
            }) {
                Text("Close")
            }
            List(Array(Set(eventsForDay.map { $0.calendarName }).sorted()), id: \.self) { calendarName in
                Toggle(isOn: Binding(
                    get: { self.calendarData.selectedCalendars.contains(calendarName) },
                    set: { newValue in
                        if newValue {
                            self.calendarData.selectedCalendars.insert(calendarName)
                        } else {
                            self.calendarData.selectedCalendars.remove(calendarName)
                        }
                    }
                )) {
                    Text(calendarName)
                }
            }
            
        }
        .padding()
        .frame(width: (UIScreen.main.bounds.size.width / 4), height: (UIScreen.main.bounds.size.height), alignment: .topLeading)
        .background(Color(UIColor.systemBackground))
        .position(x: (UIScreen.main.bounds.size.width / 8), y: UIScreen.main.bounds.size.height / 2)
    }
}

struct ContentView: View {
    @State var isCalendarAuthorized: Bool?
    @State private var showCalendarAccessAlert = false
    @AppStorage("hasRequestedCalendarAccess") var hasRequestedCalendarAccess = false
    @State private var today = Date()
    @State private var isMenuOpen = false
    @State private var isDayOpen = false
    @Binding var eventsForDay: [EventInfo]
    @Binding var tasksForDay: [TaskInfo]
    @Binding var selectedCalendars: Set<String>
    @ObservedObject var calendarData = CalendarData()
    @State private var offset: CGSize = .zero
    @State var appSettings = AppSettings()
    @Binding var dailyTasks: Set<String>
    @ObservedObject var dailyTaskData = DailyTaskData()
    
    @Binding var hideSettingsIcons: Bool
    // @ObservedObject var selectedTaskCalendar: [String]
    
    let calendar = Calendar.current
    
    //     The layer is using dynamic shadows which are expensive to render. If possible try setting `shadowPath`, or pre-rendering the shadow into an image and putting it under the layer. But they're damn good looking.
    //    //
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                WeekdayHeaderView(isMenuOpen: $isMenuOpen, isDayOpen: $isDayOpen, hideSettingsIcons: appSettings.$hideSettingsIcons)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: 40)
                if let isCalendarAuthorized = isCalendarAuthorized {
                    if isCalendarAuthorized {
                        //MinKalenderApp().weekCalendarView(forDate: today, calendarData: calendarData)
                        MinKalenderApp()
                            .weekCalendarView(forDate: today, calendarData: calendarData)
                        
                    } else {
                        Text("allow.access")
                            .onAppear {
                                if !hasRequestedCalendarAccess {
                                    requestCalendarAccess()
                                }
                            }
                    }
                } else {
                    ProgressView("loading").onAppear(perform: checkCalendarAuthorization)
                }
            }
            if isMenuOpen {
                CalendarMenuView(eventsForDay: $eventsForDay, isOpen: $isMenuOpen, selectedCalendars: $calendarData.selectedCalendars, calendarData: calendarData)
            } // Think I've gotten lazy and just adding more and more args... tidyup?
            if isDayOpen {
                
                GeometryReader { geometry in
                    
                    //      Dayview kunde dyka upp på rätt sida beroende på dag
                    //                    let dayOfWeek = calendar.component(.weekday, from: today)
                    //                    let isMondayToWednesday: Bool
                    //
                    //                    if dayOfWeek <= 3 {
                    //                        isMondayToWednesday = true
                    //                    } else {
                    //                        isMondayToWednesday = false
                    //                    }
                    //
                    //                    let xOffset: CGFloat
                    //
                    //                    if isMondayToWednesday {
                    //                        xOffset = -geometry.size.width / 2
                    //                    } else {
                    //                        xOffset = (geometry.size.width - (geometry.size.width / 3.5))
                    //                    }
                    
                    
                    //  DayView()
                    DayView(dailyTaskData: dailyTaskData, dailyTasks: $dailyTaskData.dailyTasks, taskCalendar: $dailyTaskData.taskCalendar, tasksForDay: $tasksForDay, userWantToPrintTime: appSettings.$userWantToPrintTime, hideSettingsIcons: appSettings.$hideSettingsIcons, opacityDim: appSettings.$opacityDim)
                        .frame(width: geometry.size.width / 4)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(10)
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                        .shadow(radius: 40)
                        .offset(x: max(min(offset.width, (geometry.size.width - (geometry.size.width / 3.5))), -geometry.size.width / 2), y: 0)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    offset.width = value.translation.width
                                }
                                .onEnded { value in
                                    if value.translation.width > geometry.size.width / 2 {
                                        offset = CGSize(width: geometry.size.width + (geometry.size.width / 4), height: 0)
                                    } else {
                                        offset = .zero
                                    }
                                }
                        )
                }
            }
        }
        //.background(Color(UIColor.systemGray4).opacity(appSettings.opacityDim)) // removed greying background and choose to dim foreground instead, much neeter
    }
    
    private func checkCalendarAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .event)
        isCalendarAuthorized = status == .authorized
    }
    
    private func requestCalendarAccess() {
        let eventStore = EKEventStore()
        eventStore.requestAccess(to: .event) { granted, error in
            DispatchQueue.main.async {
                hasRequestedCalendarAccess = true
                if granted {
                    isCalendarAuthorized = true
                } else {
                    showCalendarAccessAlert = true
                }
            }
        }
    }
}
