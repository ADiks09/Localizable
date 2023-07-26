import SwiftSyntax
import SwiftDiagnostics

enum LocalizableMacroDiagnostic {
    case requiresEnum
}

extension LocalizableMacroDiagnostic: DiagnosticMessage {
    var severity: DiagnosticSeverity { .error }

    var diagnosticID: MessageID {
        MessageID(domain: "Swift", id: "Localized.\(self)")
    }

    func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: Syntax(node), message: self)
    }

    var message: String {
        switch self {
        case .requiresEnum:
            return "'Localizable' macro needs an internal enum which is a set of keys for localization"
        }
    }
}
