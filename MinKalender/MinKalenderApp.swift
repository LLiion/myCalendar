import SwiftUI
import EventKit

@main
struct MinKalenderApp: App {
    @State var eventsForDay = MinaEvent.fetchCalendarsAndEventsForDate()
    @State var selectedCalendars: Set<String> = []
    
    var body: some Scene {
        WindowGroup {
            ContentView(eventsForDay: $eventsForDay, selectedCalendars: $selectedCalendars)
                .environment(\.font, Font.custom("Verdana", size: 10))
        }
    }
    
    func dateWithoutTime(_ date: Date, calendar: Calendar) -> Date {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
                        return calendar.date(from: components) ?? date
                    }
    
    private func isPastDate(_ date: Date, thisday: Date) -> Bool {
        return date < thisday
    }
    
    private func isFutureDate(_ date: Date, thisday: Date) -> Bool {
        return date > thisday
    }
    
    func weekCalendarView(forDate today: Date, selectedCalendars: Binding<Set<String>>) -> some View {
        
        let startDate = findStartOfWeek(forDate: today)
        let calendar = Calendar.current
        
        var grid: [[AnyView]] = []
        
        let daySize = (UIScreen.main.bounds.size.height / 4.0) - 20
        let innerDayHeight = (daySize / 2)
        
        let myCalendar = selectedCalendars.wrappedValue
        print("Selected Calendars: \(myCalendar)")

        
        for i in 0..<4 {
            var row: [AnyView] = []
            for j in 0..<7 {
                let day = Calendar.current.date(byAdding: .day, value: i * 7 + j, to: startDate) ?? Date()
                let thatday = dateWithoutTime(day, calendar: calendar)
                let thisday = dateWithoutTime(today, calendar: calendar)
                let isPast = isPastDate(thatday, thisday: thisday)
                let isFuture = isFutureDate(thatday, thisday: thisday)
                let dayNumber = calendar.component(.day, from: day)
                
                let eventsForCurrentDay = eventsForDay.filter { eventInfo in
                                let eventStartDate = dateWithoutTime(eventInfo.event.startDate, calendar: calendar)
                                return eventStartDate == thatday
                            }
                
                let mySelectedCalendar = selectedCalendars.wrappedValue
                let myCalendar = mySelectedCalendar.joined(separator: ", ")
                //print("\(selectedCalendars)")
                
                row.append(AnyView(
                    VStack(alignment: .leading, spacing: 0) {
                    Text("\(dayNumber)")
                        .font(.headline)
                        .foregroundColor(thatday == thisday ? .blue : isPast ? Color.gray.opacity(0.5) : Color.gray.opacity(1))
                        .background(.clear)
                        .padding(EdgeInsets(top: 2, leading: 2, bottom: 0, trailing: 0))
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Spacer()
                            if !eventsForDay.isEmpty {
                                ForEach(eventsForCurrentDay, id: \.event.eventIdentifier) { eventInfo in
                                let calendarName = eventInfo.event.calendar.title
                                
                                   // if !myCalendar.contains(calendarName) {
                                    Text(eventInfo.event.title)
                                    //.textCase(.uppercase)
                                    .foregroundColor(isPast ? Color.secondary.opacity(0.5) : isFuture ? Color.primary.opacity(0.7) : Color.primary.opacity(1))
                                    .background(.clear)
                                    .padding(EdgeInsets(top: 0, leading: 6, bottom: 2, trailing: 4))
                                    .frame(maxWidth: .infinity, maxHeight: innerDayHeight, alignment: .leading)
                                    .frame(minHeight: 0)
                                    .background(Color.clear)
                                    .listRowSeparator(.hidden)
                                  //  }
                                }
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
                        .frame(maxWidth: .infinity, maxHeight: daySize, alignment: .bottomLeading)
                    .overlay(
                        thatday == thisday ? RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.blue, lineWidth: 1)
                            .background(Color.blue.opacity(0.1)) : nil
                    )
                    .background(RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color.gray, lineWidth: 0.5)
                                    .background(Color.clear)
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)))
                    .alignmentGuide(.leading) { dimension in
                        dimension[.leading]
                    }
                ))
            }
            grid.append(row)
        }
        
        return VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { rowIndex in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { colIndex in
                        grid[rowIndex][colIndex]
                    }
                }
            }
        }
    }

        private func findStartOfWeek(forDate date: Date) -> Date {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.weekday, .year, .month, .day], from: date)
            let daysToSubtract = (components.weekday! - 2 + 7) % 7
            components.day = components.day! - daysToSubtract
            return calendar.date(from: components) ?? date
        }
    
    }
