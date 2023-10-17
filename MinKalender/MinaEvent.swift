import EventKit

struct EventInfo: Equatable {
    var event: EKEvent
    var calendarName: String
}

class MinaEvent {
    static func fetchCalendarsAndEventsForDate() -> [EventInfo] {
        let eventStore = EKEventStore()
        let calendar = Calendar.autoupdatingCurrent

        // Hitta senast passerade måndag
        var dateComponents = DateComponents()
        dateComponents.weekday = 2  // Måndag
        let today = calendar.startOfDay(for: Date())
        
        // Hitta senast passerade måndag genom att gå bakåt från idag
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
