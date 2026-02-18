// ReportsViewModel.swift
// Drives the weekly report screen

import Foundation
import Combine

@MainActor
final class ReportsViewModel: ObservableObject {

    @Published var weeklyReport: WeeklyReport?
    @Published var isLoading: Bool = false

    private let userRepository: UserRepository
    private let reportUseCase = GenerateWeeklyReportUseCase()
    private var cancellables = Set<AnyCancellable>()

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func load() {
        isLoading = true
        let allEvents = userRepository.exceedEvents
        let apps      = userRepository.monitoredApps

        let thisWeekStart = Date().startOfWeek
        let lastWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) ?? thisWeekStart
        let lastWeekEnd   = lastWeekStart.endOfWeek

        let previousEvents = allEvents.filter {
            $0.occurredAt >= lastWeekStart && $0.occurredAt <= lastWeekEnd
        }

        weeklyReport = reportUseCase.execute(
            currentEvents: allEvents,
            previousEvents: previousEvents,
            monitoredApps: apps,
            weekStart: thisWeekStart
        )
        isLoading = false
    }
}
