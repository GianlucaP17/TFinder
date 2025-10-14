//
//  Test.swift
//  GYGChallenge
//
//  Created by Gianluca Posca on 09/10/25.
//

import Foundation
import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // STEP 7: Configuriamo URLCache per caching immagini (usato anche da AsyncImage via URLSession)
        let memory = 64 * 1024 * 1024   // 64 MB in memoria
        let disk   = 256 * 1024 * 1024  // 256 MB su disco
        URLCache.shared = URLCache(memoryCapacity: memory, diskCapacity: disk, diskPath: "urlCache")
        return true
    }
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}


class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}

extension UIImage {
    static let iconStarGray: UIImage? = {
        UIImage(named: "icon_star_gray")
    }()

    static let iconStarYellow: UIImage? = {
        UIImage(named: "icon_star_yellow")
    }()
}

extension UIView {
    func pinEdges(to view: UIView, insets: UIEdgeInsets = .zero) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom)
        ])
    }

    func addSubviews(_ views: UIView...) {
        views.forEach(addSubview)
    }

    func constrainSize(to size: CGSize) {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: size.height),
            widthAnchor.constraint(equalToConstant: size.width)
        ])
    }

    func constrainHeight(to height: CGFloat) {
        heightAnchor
            .constraint(equalToConstant: height)
            .isActive = true
    }
}

extension UIStackView {
    func addArrangedSubviews(_ views: UIView...) {
        views.forEach(addArrangedSubview)
    }
}

extension UIEdgeInsets {
    init(all: CGFloat) {
        self.init(
            top: all,
            left: all,
            bottom: all,
            right: all
        )
    }
}

public struct ReviewsListView: View {
    var reviews: [Review]
    let lastRowHasAppeared: () -> Void
    var isLoading: Bool

    public var body: some View {
        // STEP 9: Navigation — abilitiamo il dettaglio tramite NavigationStack + NavigationLink
        NavigationStack {
            // STEP 7: Empty state + miglior accessibilità dello spinner
            List {
                if reviews.isEmpty && !isLoading {
                    VStack(spacing: 8) {
                        Image(systemName: "text.bubble")
                        Text("No reviews yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                    .listRowSeparator(.hidden)
                } else {
                    
                    // FIX Step 1 mantenuto: identità stabile per ogni review.
                    ForEach(reviews, id: \.id) { review in
                        NavigationLink {
                            ReviewDetailView(review: review)
                        } label: {
                            ReviewView(review: review)
                        }
                        .onAppear {
                            // Trigger "carica altro" sull'ultima cella (i guardrail sono nel controller/ViewModel).
                            if reviews.last?.id == review.id {
                                lastRowHasAppeared()
                            }
                        }
                    }

                    if isLoading {
                        // STEP 3.1 + 7: Indicatore di caricamento con etichetta accessibile.
                        HStack {
                            Spacer()
                            VStack(spacing: 6) {
                                ProgressView()
                                Text("Loading more reviews…")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 12)
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Loading more reviews")
                    }
                }
            }
            .navigationTitle("Reviews")
        }
    }
    
    // STEP ULTIMO > DETAIL
struct ReviewDetailView: View {
    let review: Review

    private static let df: DateFormatter = {
        let d = DateFormatter()
        d.dateStyle = .medium
        return d
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let created = review.created {
                    Text(Self.df.string(from: created))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                RatingView(ratingValue: review.rating)
                if let msg = review.message { Text(msg).font(.body) }
                AuthorView(authorInfo: review.author, reviewID: review.id)
            }
            .padding()
        }
        .navigationTitle("Review #\(review.id)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
}

struct ReviewView: View {
    let review: Review
    
    private let formattedDate: String?
    
    init(review: Review) {
        self.review = review
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        formattedDate = review.created.map(dateFormatter.string(from:))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let formattedDate {
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            RatingView(ratingValue: review.rating)
            if let reviewMessage = review.message {
                Text(reviewMessage)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            AuthorView(
                authorInfo: review.author,
                reviewID: review.id
            )
        }
    }
}

struct AuthorView: View {
    let authorInfo: AuthorInfo?
    let reviewID: Int

    private let reviewLabel: String
    private let photoURL: URL?

    init(authorInfo: AuthorInfo?, reviewID: Int) {
        self.authorInfo = authorInfo
        self.reviewID = reviewID

        var reviewedByContentText = authorInfo?.fullName ?? "Anonymous"
        if let country = authorInfo?.country {
            reviewedByContentText = "\(reviewedByContentText) - \(country)"
        }
        self.reviewLabel = reviewedByContentText

        // STEP 5.1: Pre-calcoliamo la URL (se esiste) da usare nel body con AsyncImage.
        // Motivazione: niente I/O sincrono (Data(contentsOf:)) sul main thread, niente force-unwrap URL.
        if let photo = authorInfo?.photo(reviewID: reviewID), let url = URL(string: photo) {
            self.photoURL = url
        } else {
            self.photoURL = nil
        }
    }

    // STEP 7: Initials per avatar placeholder (miglior feedback quando manca/fallisce la foto)
    private var initials: String {
        let name = authorInfo?.fullName.trimmingCharacters(in: .whitespacesAndNewlines) ?? "A"
        let parts = name.split(separator: " ")
        let chars = parts.prefix(2).compactMap { $0.first }
        return String(chars).uppercased()
    }

    var body: some View {
        HStack(spacing: 10) {
            // STEP 5.1: Immagine asincrona con placeholder — UI reattiva, nessun blocco.
            if let url = photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 44, height: 44)
                    case .success(let image):
                        image
                            .resizable()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .accessibilityHidden(true)
                    case .failure:
                        ZStack {
                            Circle().frame(width: 44, height: 44).opacity(0.15)
                            Text(initials).font(.caption).bold()
                        }
                        .accessibilityHidden(true)
                    @unknown default:
                        ZStack {
                            Circle().frame(width: 44, height: 44).opacity(0.15)
                            Text(initials).font(.caption).bold()
                        }
                        .accessibilityHidden(true)
                    }
                }
            } else {
                // Nessuna foto: placeholder con iniziali (evita layout jump e aiuta il riconoscimento visivo)
                ZStack {
                    Circle().frame(width: 44, height: 44).opacity(0.15)
                    Text(initials).font(.caption).bold()
                }
                .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("reviewed by")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(reviewLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        // Accessibilità: combiniamo i testi; l'immagine è decorativa.
        .accessibilityElement(children: .combine)
    }
}

struct RatingView: View {
    let ratingValue: Int
    let maxRating: Int = 5

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...maxRating, id: \.self) { index in
                // STEP 5.1: Evitiamo force-unwrap su asset di immagini.
                // Pro: niente crash se asset mancano, supporta Dynamic Type e tema.
                // Contro: stile diverso dagli asset custom; si può sostituire con immagini custom se richiesto dal design.
                Image(systemName: index <= ratingValue ? "star.fill" : "star")
            }
        }
        .accessibilityLabel("Rating \(ratingValue) of \(maxRating)")
    }
}

enum NetworkError: Error, Equatable {
    case cancelled
    case noData
    case noInternet
    case notFound
    case timeout
    case underlying(_ error: NSError)
    case unknown
}

protocol NetworkTask {
    func resume()
    func suspend()
    func cancel()
}

extension URLSessionTask: NetworkTask { }

protocol NetworkClientProtocol {
    // STEP 5: Overload async — più idiomatico con Swift Concurrency
    func run<ResponseBody: Decodable>(_ request: URLRequest) async -> Result<ResponseBody, NetworkError>

    // Compat: manteniamo la versione a callback per chiamanti legacy
    @discardableResult
    func run<ResponseBody: Decodable>(
        _ request: URLRequest,
        completion: @escaping (Result<ResponseBody, NetworkError>) -> Void
    ) -> NetworkTask
}

protocol URLSessionProtocol {
    // STEP 5: API async/await nativa (iOS 15+)
    func data(for request: URLRequest) async throws -> (Data, URLResponse)

    // Compat: teniamo anche l'API a callback per codice legacy/test esistenti
    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask
}

extension URLSession: URLSessionProtocol {}

class NetworkClient: NetworkClientProtocol {
    var jsonDecoder = JSONDecoder()
    var urlSession: URLSessionProtocol = URLSession.shared

    @discardableResult
    func run<ResponseBody: Decodable>(
        _ request: URLRequest,
        completion: @escaping (Result<ResponseBody, NetworkError>) -> Void
    ) -> NetworkTask {
        // LOG: stampa essenziale (evita il debugDescription prolisso). Mostra metodo e URL.
        print("\nHTTP Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "<nil>")")

        let task = urlSession.dataTask(with: request) { data, response, error in
            // 1) Errori di trasporto (rete) prima: mappa URLError → NetworkError specifici
            if let urlError = error as? URLError {
                switch urlError.code {
                case .cancelled:              return completion(.failure(.cancelled))
                case .timedOut:               return completion(.failure(.timeout))
                case .notConnectedToInternet: return completion(.failure(.noInternet))
                default:                      return completion(.failure(.underlying(urlError as NSError)))
                }
            } else if let nsError = error as NSError? {
                // Errore generico non-URLError
                return completion(.failure(.underlying(nsError)))
            }

            // 2) Validazione risposta HTTP
            guard let http = response as? HTTPURLResponse else {
                // Nessuna risposta HTTP: stato sconosciuto (es. problemi di sessione)
                return completion(.failure(.unknown))
            }

            let status = http.statusCode
            guard (200...299).contains(status) else {
                // Mappatura minima codici comuni; il resto come underlying
                if status == 404 { return completion(.failure(.notFound)) }
                if status == 408 { return completion(.failure(.timeout)) }
                let httpError = NSError(domain: "HTTPError", code: status, userInfo: nil)
                return completion(.failure(.underlying(httpError)))
            }

            // 3) Verifica dati e decoding
            guard let data = data, !data.isEmpty else {
                return completion(.failure(.noData))
            }

            // LOG: pretty print JSON quando possibile (supporta oggetto o array come root)
            if let pretty = data.prettyPrintedJSONString {
                print("\nHTTP Response (\(status)): \(pretty)")
            }

            do {
                let decoded = try self.jsonDecoder.decode(ResponseBody.self, from: data)
                completion(.success(decoded))
            } catch {
                // Decoding fallito: esponi errore sottostante per diagnosi
                completion(.failure(.underlying(error as NSError)))
            }
        }
        task.resume()

        return task
    }

    // STEP 5: Implementazione async/await parallela all'API a callback
    func run<ResponseBody: Decodable>(_ request: URLRequest) async -> Result<ResponseBody, NetworkError> {
        // LOG essenziale
        print("\nHTTP Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "<nil>")")
        do {
            let (data, response) = try await urlSession.data(for: request)

            // Validazione HTTP
            guard let http = response as? HTTPURLResponse else {
                return .failure(.unknown)
            }
            let status = http.statusCode
            guard (200...299).contains(status) else {
                if status == 404 { return .failure(.notFound) }
                if status == 408 { return .failure(.timeout) }
                let httpError = NSError(domain: "HTTPError", code: status)
                return .failure(.underlying(httpError))
            }

            guard !data.isEmpty else { return .failure(.noData) }

            if let pretty = data.prettyPrintedJSONString {
                print("\nHTTP Response (\(status)): \(pretty)")
            }

            do {
                let decoded = try self.jsonDecoder.decode(ResponseBody.self, from: data)
                return .success(decoded)
            } catch {
                return .failure(.underlying(error as NSError))
            }
        } catch {
            // Mapping errori di trasporto
            if let urlError = error as? URLError {
                switch urlError.code {
                case .cancelled:              return .failure(.cancelled)
                case .timedOut:               return .failure(.timeout)
                case .notConnectedToInternet: return .failure(.noInternet)
                default:                      return .failure(.underlying(urlError as NSError))
                }
            }
            return .failure(.underlying(error as NSError))
        }
    }
}

private extension Data {
    var prettyPrintedJSONString: String? {
        // FIX: supporta sia dizionari che array come root; se non è JSON valido, ritorna nil senza crash.
        guard
            let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
            let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
        else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}

// STEP 4: Service per incapsulare il trasporto e preparare la DI
protocol ReviewsService {
    // STEP 5: API async per il service
    func fetchReviews(
        activityId: Int,
        offset: Int
    ) async -> Result<ReviewsResponse, NetworkError>
}

struct DefaultReviewsService: ReviewsService {
    let client: NetworkClientProtocol

    func fetchReviews(
        activityId: Int,
        offset: Int
    ) async -> Result<ReviewsResponse, NetworkError> {
        var components = URLComponents(string: "https://travelers-api.getyourguide.com/activities/\(activityId)/reviews")!
        components.queryItems = [URLQueryItem(name: "offset", value: String(offset))]
        let request = URLRequest(url: components.url!)
        return await client.run(request)
    }
}

// STEP 8: Clean Architecture boundaries — Domain Repository + UseCase, Data Repository implementation
// Domain — Repository astrae la fonte dati
protocol ReviewsRepository {
    func fetchReviews(activityId: Int, offset: Int) async -> Result<ReviewsResponse, NetworkError>
}

// Data — implementazione del Repository che delega al service (trasporto HTTP)
struct DefaultReviewsRepository: ReviewsRepository {
    let service: ReviewsService
    func fetchReviews(activityId: Int, offset: Int) async -> Result<ReviewsResponse, NetworkError> {
        await service.fetchReviews(activityId: activityId, offset: offset)
    }
}

// Domain — UseCase esplicita il caso d'uso dell'applicazione
protocol FetchReviewsPageUseCase {
    func execute(activityId: Int, offset: Int) async -> Result<ReviewsResponse, NetworkError>
}

struct DefaultFetchReviewsPageUseCase: FetchReviewsPageUseCase {
    let repository: ReviewsRepository
    func execute(activityId: Int, offset: Int) async -> Result<ReviewsResponse, NetworkError> {
        await repository.fetchReviews(activityId: activityId, offset: offset)
    }
}

// STEP 8: ViewModel dipende da un UseCase (DIP) — nessuna conoscenza del trasporto o del service
final class ReviewsViewModel {
    private let activityId: Int
    private let useCase: FetchReviewsPageUseCase

    // Stato esposto in sola lettura verso l'esterno (il VC lo usa per aggiornare la UI)
    private(set) var reviews: [Review] = []
    private(set) var isLoading: Bool = false
    private(set) var hasMore: Bool = true

    // Callbacks per notificare cambiamenti di stato al VC
    var onChange: (() -> Void)?

    init(activityId: Int, useCase: FetchReviewsPageUseCase) {
        self.activityId = activityId
        self.useCase = useCase
    }

    func fetchReviews() {
        // Guardrail di paginazione
        guard hasMore, !isLoading else { return }
        isLoading = true
        // Notifica immediata per mostrare lo spinner (Step 3.1)
        onChange?()

        Task { [weak self] in
            guard let self = self else { return }
            let result = await useCase.execute(activityId: activityId, offset: reviews.count)
            switch result {
            case .success(let response):
                self.reviews.append(contentsOf: response.reviews)
                self.reviews = self.reviews.uniqued() // dedup preservando l'ordine
                self.hasMore = self.reviews.count < response.totalCount
            case .failure:
                // Strategia prudente: evitiamo retry a raffica; UI di retry/backoff in step successivi
                self.hasMore = false
            }
            self.isLoading = false
            self.onChange?()
        }
    }
}


struct ReviewsResponse: Codable {
    var averageRating: Float
    var pagination: Pagination?
    var reviews: [Review]
    var totalCount: Int
}

/// A review is always attached to an Activity. Each activity can have multiple reviews
struct Review: Codable, Equatable, Hashable {
    /// A unique identifier for the activity that is reviewed
    var activityId: Int

    /// A unique identifier, guaranteed to identify a review uniquely
    var id: Int

    var author: AuthorInfo?
    var created: Date?
    var enjoyment: String?
    var message: String?
    var rating: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct AuthorInfo: Codable, Equatable {
    var fullName: String
    var country: String?
}

extension AuthorInfo {
    func photo(reviewID: Int) -> String? {
        reviewID % 2 == 0
        ? "https://picsum.photos/300/300?lock=\(reviewID)"
        : nil
    }
}

struct Pagination: Codable, Equatable {
    var limit: Int?
    var offset: Int?
}

class ViewController: UIViewController {
    let activityId: Int = 251502

    var networkClient: NetworkClient = {
        let networkClient = NetworkClient()

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        networkClient.jsonDecoder = jsonDecoder

        return networkClient
    }()

    private lazy var viewModel: ReviewsViewModel = {
        // STEP 8: Composition Root — costruiamo la catena DI esplicita
        let service = DefaultReviewsService(client: self.networkClient)               // Data Source (HTTP)
        let repository = DefaultReviewsRepository(service: service)                    // Data → Domain
        let useCase = DefaultFetchReviewsPageUseCase(repository: repository)          // Domain UseCase
        return ReviewsViewModel(activityId: self.activityId, useCase: useCase)        // Presentation dipende dal caso d'uso
    }()

    // STEP 4.1: Evitiamo di creare più UIHostingController — ne riusiamo uno solo.
    private var hostingController: UIHostingController<ReviewsListView>?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Reviews for Activity ID \(activityId)"

        // STEP 4: il VC osserva i cambiamenti del ViewModel e aggiorna la UI
        viewModel.onChange = { [weak self] in
            DispatchQueue.main.async {
                self?.addReviewsViewController()
            }
        }

        // Primo fetch
        viewModel.fetchReviews()
    }

    func addReviewsViewController() {
        let root = ReviewsListView(
            reviews: viewModel.reviews,
            lastRowHasAppeared: { [weak self] in
                self?.viewModel.fetchReviews()
            },
            isLoading: viewModel.isLoading
        )

        if let hostingController {
            // STEP 4.1: Reuse — aggiorniamo solo la rootView, niente re-add.
            hostingController.rootView = root
            return
        }

        // Prima inizializzazione: creiamo e montiamo l'HostingController una sola volta.
        let host = UIHostingController(rootView: root)
        hostingController = host

        addChild(host)
        if let view = viewIfLoaded {
            view.addSubview(host.view)
            host.view.frame = view.bounds
            host.view.pinEdges(to: view)
        }
        host.didMove(toParent: self)
    }

}

#if DEBUG
import Foundation

// MARK: - Step 6 Lightweight Tests (no XCTest required)
// Esegui con: await Step6Tests.runAll() da un punto di debug o in un'anteprima SwiftUI.

enum Step6Tests {
    static func runAll() async {
        print("\n—— Step6Tests: start ——")
        testDecoding()
        await testNetworkMapping_timeout()
        await testNetworkMapping_404()
        await testViewModelPagination()
        print("—— Step6Tests: end ——\n")
    }

    // MARK: Decoding JSON (ISO8601)
    static func testDecoding() {
        let json = """
        {
          "averageRating": 4.5,
          "pagination": { "limit": 2, "offset": 0 },
          "reviews": [
            { "activityId": 1, "id": 10, "author": { "fullName": "Alice", "country": "DE" }, "created":"2024-01-01T12:00:00Z", "message":"ok", "rating":5 },
            { "activityId": 1, "id": 11, "author": { "fullName": "Bob" }, "created":"2024-01-02T12:00:00Z", "message":"meh", "rating":3 }
          ],
          "totalCount": 2
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let r = try decoder.decode(ReviewsResponse.self, from: json)
            tassert(r.reviews.count == 2, "Decoding: reviews count == 2")
            tassert(r.reviews[0].id == 10 && r.reviews[1].id == 11, "Decoding: ids decoded correctly")
            tassert(r.reviews[0].created != nil, "Decoding: date ISO8601 parsed")
        } catch {
            tassert(false, "Decoding failed with error: \(error)")
        }
    }

    // MARK: NetworkClient mapping — timeout
    static func testNetworkMapping_timeout() async {
        let client = NetworkClient()
        let mock = MockURLSession()
        mock.nextError = URLError(.timedOut)
        client.urlSession = mock
        let req = URLRequest(url: URL(string: "https://example.com/test")!)
        let result: Result<ReviewsResponse, NetworkError> = await client.run(req)
        tassert(result == .failure(.timeout), "Network mapping: URLError.timedOut → .timeout")
    }

    // MARK: NetworkClient mapping — 404
    static func testNetworkMapping_404() async {
        let client = NetworkClient()
        let mock = MockURLSession()
        mock.nextData = Data("{}".utf8)
        mock.nextResponse = HTTPURLResponse(url: URL(string: "https://example.com/test")!, statusCode: 404, httpVersion: nil, headerFields: nil)
        client.urlSession = mock
        let req = URLRequest(url: URL(string: "https://example.com/test")!)
        let result: Result<ReviewsResponse, NetworkError> = await client.run(req)
        tassert(result == .failure(.notFound), "Network mapping: 404 → .notFound")
    }

    // MARK: ViewModel — paginazione e guardrail
    static func testViewModelPagination() async {
        let page1: [Review] = [
            .init(activityId: 1, id: 1, author: nil, created: nil, enjoyment: nil, message: nil, rating: 5),
            .init(activityId: 1, id: 2, author: nil, created: nil, enjoyment: nil, message: nil, rating: 4)
        ]
        let page2: [Review] = [
            .init(activityId: 1, id: 3, author: nil, created: nil, enjoyment: nil, message: nil, rating: 3)
        ]
        let mockUseCase = MockFetchReviewsPageUseCase(pages: [page1, page2], totalCount: 3)
        let vm = ReviewsViewModel(activityId: 1, useCase: mockUseCase)

        var changeCount = 0
        vm.onChange = { changeCount += 1 }

        vm.fetchReviews() // pagina 1
        try? await Task.sleep(nanoseconds: 150_000_000)
        tassert(vm.reviews.count == 2 && vm.hasMore == true, "VM: dopo pagina 1, count=2, hasMore=true")

        vm.fetchReviews() // pagina 2
        try? await Task.sleep(nanoseconds: 150_000_000)
        tassert(vm.reviews.count == 3 && vm.hasMore == false, "VM: dopo pagina 2, count=3, hasMore=false")

        let callsBefore = mockUseCase.calls
        vm.fetchReviews() // non deve chiamare più (hasMore=false)
        try? await Task.sleep(nanoseconds: 100_000_000)
        tassert(mockUseCase.calls == callsBefore, "VM: nessuna chiamata extra quando hasMore=false")
        tassert(changeCount >= 2, "VM: onChange chiamato almeno due volte")
    }
}

// MARK: - Mocks (Debug-only)
final class MockURLSession: URLSessionProtocol {
    var nextData: Data?
    var nextResponse: URLResponse?
    var nextError: Error?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = nextError { throw error }
        return (nextData ?? Data(), nextResponse ?? URLResponse())
    }

    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        MockURLSessionDataTask { [nextData, nextResponse, nextError] in
            completionHandler(nextData, nextResponse, nextError)
        }
    }
}

final class MockURLSessionDataTask: URLSessionDataTask {
    private let onResume: () -> Void
    init(onResume: @escaping () -> Void) { self.onResume = onResume }
    override func resume() { onResume() }
    override func suspend() {}
    override func cancel() {}
}

final class MockReviewsService: ReviewsService {
    private let pages: [[Review]]
    private let total: Int
    private(set) var calls: Int = 0

    init(pages: [[Review]], totalCount: Int) {
        self.pages = pages
        self.total = totalCount
    }

    func fetchReviews(activityId: Int, offset: Int) async -> Result<ReviewsResponse, NetworkError> {
        let idx = calls
        calls += 1
        let page = idx < pages.count ? pages[idx] : []
        let response = ReviewsResponse(
            averageRating: 4.0,
            pagination: Pagination(limit: page.count, offset: offset),
            reviews: page,
            totalCount: total
        )
        return .success(response)
    }
}

final class MockFetchReviewsPageUseCase: FetchReviewsPageUseCase {
    private let pages: [[Review]]
    private let total: Int
    private(set) var calls: Int = 0

    init(pages: [[Review]], totalCount: Int) {
        self.pages = pages
        self.total = totalCount
    }

    func execute(activityId: Int, offset: Int) async -> Result<ReviewsResponse, NetworkError> {
        let idx = calls
        calls += 1
        let page = idx < pages.count ? pages[idx] : []
        let response = ReviewsResponse(
            averageRating: 4.0,
            pagination: Pagination(limit: page.count, offset: offset),
            reviews: page,
            totalCount: total
        )
        return .success(response)
    }
}

// Tiny assertion helper (non interrompe il flusso in release)
@inline(__always)
private func tassert(_ condition: @autoclosure () -> Bool, _ message: String) {
    if condition() {
        print("✅ \(message)")
    } else {
        print("❌ ASSERT: \(message)")
    }
}
#endif
