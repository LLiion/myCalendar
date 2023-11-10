import EventKit

struct EventInfo: Equatable {
    var event: EKEvent
    var calendarName: String
    var stackingNumber: Int?
}

class MinaEvent {
    static func fetchCalendarsAndEventsForDate() -> [EventInfo] {
        let eventStore = EKEventStore()
        let calendar = Calendar.autoupdatingCurrent

        var dateComponents = DateComponents()
        dateComponents.weekday = 2  // Måndag
        let today = calendar.startOfDay(for: Date())
        
        guard let lastMonday = calendar.date(byAdding: .day, value: -7, to: today),
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastMonday)) else {
                return []
        }

        guard let endDate = calendar.date(byAdding: .day, value: 35, to: startOfWeek) else {
            return []
        }

        let predicate = eventStore.predicateForEvents(withStart: startOfWeek, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)

        var eventInfoList: [EventInfo] = []

        for event in events {
            let calendarName = event.calendar.title
            let eventInfo = EventInfo(event: event, calendarName: calendarName)
            eventInfoList.append(eventInfo)
        }

        return eventInfoList
    }
}

struct TaskInfo: Equatable {
    var task: EKEvent
    var calendarName: String
    var stackingNumber: Int?
    var index: Int?
}

class MyTasks {
    static func fetchTasksForDate() -> [TaskInfo] {
        let eventStore = EKEventStore()
        let calendar = Calendar.autoupdatingCurrent

        var dateComponents = DateComponents()
        dateComponents.weekday = 2  // Måndag
        let today = calendar.startOfDay(for: Date())
        
        guard let lastMonday = calendar.date(byAdding: .day, value: -7, to: today),
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastMonday)) else {
                return []
        }

        guard let endDate = calendar.date(byAdding: .day, value: 35, to: startOfWeek) else {
            return []
        }

        let predicate = eventStore.predicateForEvents(withStart: startOfWeek, end: endDate, calendars: nil)
        let tasks = eventStore.events(matching: predicate)
        
        var taskInfoList: [TaskInfo] = []

        for task in tasks {
            let calendarName = task.calendar.title
            
            let components = calendar.dateComponents([.hour, .minute], from: task.startDate)
            let stackingNumber = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            let taskInfo = TaskInfo(task: task, calendarName: calendarName, stackingNumber: stackingNumber)
            
            taskInfoList.append(taskInfo)
        }

        return taskInfoList
    }
}
