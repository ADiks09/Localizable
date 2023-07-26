import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct LocalizableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.memberBlock.members.compactMap(asEnumDecl).first else {
            context.diagnose(LocalizableMacroDiagnostic.requiresEnum.diagnose(at: declaration))
            return []
        }
        let enumCases = enumDecl.memberBlock.members.flatMap(asEnumCaseDecl)
        let enumMembers = enumCases.map(casesToEnumMembers)
        return enumMembers
    }

    private static func asEnumDecl(_ member: MemberDeclListItemSyntax) -> EnumDeclSyntax? {
        member.decl.as(EnumDeclSyntax.self)
    }
    
    private static func asEnumCaseDecl(_ member: MemberDeclListItemSyntax) -> [EnumCaseElementSyntax] {
        guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
            return [EnumCaseElementSyntax]()
        }
        return Array(caseDecl.elements)
    }
    
    private static func casesToEnumMembers(_ element: EnumCaseElementSyntax) -> DeclSyntax {
        if element.associatedValue != nil {
            return makeStaticFunc(from: element)
        }
        return makeStaticField(from: element)
    }

    private static func makeStaticField(from element: EnumCaseElementSyntax) -> DeclSyntax {
        """
        static let \(element.identifier) = NSLocalizedString("\(element.identifier)", comment: "")
        """
    }
    
    private static func makeStaticFunc(from element: EnumCaseElementSyntax) -> DeclSyntax {
        let parameterList = element.associatedValue?.parameterList ?? []
        let syntax = """
        static func \(element.identifier)(\(makeFuncParameters(from: parameterList))) -> String {
            String(format: NSLocalizedString("\(element.identifier)", comment: ""),\(makeFuncArguments(from: parameterList)))
        }
        """
        return DeclSyntax(stringLiteral: syntax)
    }

    private static func makeFuncParameters(from list: EnumCaseParameterListSyntax) -> String {
        list
            .enumerated()
            .map { "_ value\($0): \($1.type.as(SimpleTypeIdentifierSyntax.self)!.name.text)" }
            .joined(separator: ",")
    }

    private static func makeFuncArguments(from list: EnumCaseParameterListSyntax) -> String {
        list
            .enumerated()
            .map { " value\($0.offset)" }
            .joined(separator: ",")
    }
}

@main
struct LocalizablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        LocalizableMacro.self,
    ]
}
