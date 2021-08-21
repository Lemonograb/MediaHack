import UIKit

public enum Device {
    public static let isPhone = UIDevice.current.userInterfaceIdiom == .phone
}
