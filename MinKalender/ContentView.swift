import SwiftUI
import EventKit
import Foundation

struct WeekdayHeaderView: View {
    let weekdays = ["Mån", "Tis", "Ons", "Tor", "Fre", "Lör", "Sön"]

    @Binding var isMenuOpen: Bool

    var body: some View {
        HStack {
            Button(action: {
                isMenuOpen.toggle()
            }) {
                Image(systemName: "line.horizontal.3") // Symbolen för en menyknapp
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
            }
            
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.headline)
                    .textCase(.uppercase)
                    .padding(.horizontal, 5)
                    .frame(maxWidth: .infinity)
                    .offset(x: -25)
            }
        }
        .background(Color.clear)
        .foregroundColor(.gray)
    }
}

class CalendarData: ObservableObject {
    @Published var selectedCalendars: Set<String> {
        didSet {
            saveSelectedCalendars()
            print("Selected calendars saved: \(selectedCalendars)")
        }
    }

    init() {
        print("Initializing CalendarData")
        if let savedCalendars = UserDefaults.standard.stringArray(forKey: "selectedCalendars") {
            self.selectedCalendars = Set(savedCalendars)
        } else {
            self.selectedCalendars = Set(["Hem"])
        }
        print(selectedCalendars)
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
    @StateObject private var calendarData = CalendarData()

    var body: some View {
        VStack {
            Button(action: {
                isOpen.toggle()
            }) {
                Text("Stäng meny")
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
        .shadow(color: Color(UIColor.systemGray).opacity(0.3), radius: 5, x: 2, y: 2)
        .position(x: (UIScreen.main.bounds.size.width / 8), y: UIScreen.main.bounds.size.height / 2)
        }
    }

struct ContentView: View {
    @State private var isCalendarAuthorized: Bool?
    @State private var showCalendarAccessAlert = false
    @AppStorage("hasRequestedCalendarAccess") private var hasRequestedCalendarAccess = false
    @State private var today = Date()
    @State private var isMenuOpen = false
    @Binding var eventsForDay: [EventInfo]
    @Binding var selectedCalendars: Set<String>
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                WeekdayHeaderView(isMenuOpen: $isMenuOpen)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: 40)
                    
                if let isCalendarAuthorized = isCalendarAuthorized {
                    if isCalendarAuthorized {
                        MinKalenderApp(eventsForDay: eventsForDay).weekCalendarView(forDate: today, selectedCalendars: $selectedCalendars)
                    } else {
                        Text("Tillåt kalendertillgång")
                            .onAppear {
                                if !hasRequestedCalendarAccess {
                                    requestCalendarAccess()
                                }
                            }
                    }
                } else {
                    ProgressView("Laddar...").onAppear(perform: checkCalendarAuthorization)
                }
               
            }
            
            if isMenuOpen {
                CalendarMenuView(eventsForDay: $eventsForDay, isOpen: $isMenuOpen, selectedCalendars: $selectedCalendars)
            }
        }
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
