import Localizable
import Foundation

@Localizable
internal struct Localization {
    private enum Strings {
        case login_welcome
        case login_message(String)
    }
}

print(Localization.login_welcome)

