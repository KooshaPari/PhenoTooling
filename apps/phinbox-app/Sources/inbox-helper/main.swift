// Phinbox Inbox Helper - Native macOS WKWebView wrapper
// Compiles with: swiftc -o inbox-helper main.swift -framework Cocoa -framework WebKit

import Cocoa
import WebKit

// MARK: - Constants

let kInboxURL = URL(string: "http://127.0.0.1:7117/inbox/")!
let kRetryInterval: TimeInterval = 2.0
let kInitialWidth: CGFloat = 1024
let kInitialHeight: CGFloat = 768
let kMinWidth: CGFloat = 640
let kMinHeight: CGFloat = 480
let kWindowAutosaveName = "PhinboxWindowFrame"

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    var loadingIndicator: NSProgressIndicator!
    var loadingLabel: NSTextField!
    var statusLabel: NSTextField!
    var retryTimer: Timer?
    var isRetrying = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWindow()
        setupWebView()
        setupLoadingIndicator()
        setupStatusLabel()
        loadInboxURL()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    @objc func reloadPage(_ sender: Any?) {
        webView.reload()
    }

    // MARK: - Window Setup

    private func setupWindow() {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let width = min(kInitialWidth, screenFrame.width * 0.8)
        let height = min(kInitialHeight, screenFrame.height * 0.8)
        let x = screenFrame.midX - width / 2
        let y = screenFrame.midY - height / 2

        let contentRect = NSRect(x: x, y: y, width: width, height: height)
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]

        window = NSWindow(contentRect: contentRect, styleMask: styleMask, backing: .buffered, defer: false)
        window.title = "Phinbox"
        window.minSize = NSSize(width: kMinWidth, height: kMinHeight)
        window.backgroundColor = NSColor(calibratedRed: 0.059, green: 0.090, blue: 0.165, alpha: 1.0)
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        window.isMovableByWindowBackground = true
        window.setFrameAutosaveName(kWindowAutosaveName)
        window.standardWindowButton(.closeButton)?.toolTip = "Close (Cmd+W)"
    }

    // MARK: - WebView Setup

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.setValue(false, forKey: "drawsBackground")

        webView.layer?.backgroundColor = NSColor(calibratedRed: 0.059, green: 0.090, blue: 0.165, alpha: 1.0).cgColor

        webView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView?.addSubview(webView)

        if let contentView = window.contentView {
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: contentView.topAnchor),
                webView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                webView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            ])
        }
    }

    // MARK: - Loading Indicator

    private func setupLoadingIndicator() {
        loadingIndicator = NSProgressIndicator()
        loadingIndicator.style = .spinning
        loadingIndicator.controlSize = .regular
        loadingIndicator.isIndeterminate = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.isHidden = true
        window.contentView?.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: window.contentView!.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: window.contentView!.centerYAnchor, constant: -20),
        ])
    }

    private func setupStatusLabel() {
        loadingLabel = NSTextField(labelWithString: "Loading inbox...")
        loadingLabel.textColor = NSColor.secondaryLabelColor
        loadingLabel.font = NSFont.systemFont(ofSize: 14)
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingLabel.isHidden = true
        window.contentView?.addSubview(loadingLabel)

        NSLayoutConstraint.activate([
            loadingLabel.centerXAnchor.constraint(equalTo: window.contentView!.centerXAnchor),
            loadingLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 12),
        ])

        statusLabel = NSTextField(labelWithString: "")
        statusLabel.textColor = NSColor.secondaryLabelColor
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.isHidden = true
        window.contentView?.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: window.contentView!.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: loadingLabel.bottomAnchor, constant: 8),
        ])
    }

    private func showLoading(_ show: Bool, message: String? = nil) {
        loadingIndicator.isHidden = !show
        loadingLabel.isHidden = !show
        if show {
            loadingIndicator.startAnimation(nil)
            if let msg = message {
                loadingLabel.stringValue = msg
            }
        } else {
            loadingIndicator.stopAnimation(nil)
            statusLabel.isHidden = true
        }
    }

    // MARK: - URL Loading

    private func loadInboxURL() {
        showLoading(true, message: "Loading inbox...")
        stopRetrying()

        let request = URLRequest(url: kInboxURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        webView.load(request)
    }

    private func startRetrying() {
        guard !isRetrying else { return }
        isRetrying = true
        showLoading(true, message: "Waiting for Phinbox daemon...")
        statusLabel.stringValue = "Retrying in \(Int(kRetryInterval))s..."
        statusLabel.isHidden = false

        retryTimer = Timer.scheduledTimer(withTimeInterval: kRetryInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.statusLabel.stringValue = "Trying to connect..."
            self.webView.load(URLRequest(url: kInboxURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10))
        }
    }

    private func stopRetrying() {
        isRetrying = false
        retryTimer?.invalidate()
        retryTimer = nil
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        showLoading(true, message: "Loading inbox...")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        showLoading(false)
        stopRetrying()

        // Inject dark theme CSS for any unstyled elements
        let css = """
            html, body {
                background-color: #0f172a !important;
                color: #e2e8f0 !important;
            }
            """
        let script = """
            var style = document.createElement('style');
            style.textContent = `\(css)`;
            document.head.appendChild(style);
            """
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                print("CSS injection warning: \(error.localizedDescription)")
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleLoadError(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleLoadError(error)
    }

    private func handleLoadError(_ error: Error) {
        let nsError = error as NSError
        // -1004 = cannot connect, -1003 = cannot find host, -1001 = timed out
        let retryCodes: Set<Int> = [-1009, -1004, -1003, -1001, -1020]
        if retryCodes.contains(nsError.code) {
            startRetrying()
        } else {
            showLoading(true, message: "Connection error")
            statusLabel.stringValue = error.localizedDescription
            statusLabel.isHidden = false
            startRetrying()
        }
    }

    // MARK: - WKUIDelegate

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            NSWorkspace.shared.open(url)
        }
        return nil
    }
}

// MARK: - Main Entry Point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)

// Create main menu with standard shortcuts
let mainMenu = NSMenu()

// App menu
let appMenuItem = NSMenuItem()
mainMenu.addItem(appMenuItem)
let appMenu = NSMenu()
appMenu.addItem(withTitle: "About Phinbox", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
appMenu.addItem(NSMenuItem.separator())
appMenu.addItem(withTitle: "Quit Phinbox", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
appMenuItem.submenu = appMenu

// Edit menu
let editMenuItem = NSMenuItem()
mainMenu.addItem(editMenuItem)
let editMenu = NSMenu(title: "Edit")
editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
editMenu.addItem(NSMenuItem.separator())
editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
editMenuItem.submenu = editMenu

// View menu
let viewMenuItem = NSMenuItem()
mainMenu.addItem(viewMenuItem)
let viewMenu = NSMenu(title: "View")
viewMenu.addItem(withTitle: "Reload", action: #selector(AppDelegate.reloadPage(_:)), keyEquivalent: "r")
viewMenuItem.submenu = viewMenu

app.mainMenu = mainMenu

// Run the event loop (window shown in applicationDidFinishLaunching)
app.run()
