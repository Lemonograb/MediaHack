import UIKit

protocol Blurable {
    var layer: CALayer { get }
    var subviews: [UIView] { get }
    var frame: CGRect { get }
    var superview: UIView? { get }

    func add(subview: UIView)
    func removeFromSuperview()

    func blur(radius: CGFloat)
    func unBlur()

    var isBlurred: Bool { get }
}

extension Blurable {
    func blur(radius: CGFloat) {
        if superview == nil {
            return
        }

        UIGraphicsBeginImageContextWithOptions(CGSize(width: frame.width, height: frame.height), false, 1)

        guard let context = UIGraphicsGetCurrentContext() else { return }
        layer.render(in: context)

        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return }

        UIGraphicsEndImageContext()

        guard
            let blur = CIFilter(name: "CIGaussianBlur"),
            let this = self as? UIView
        else {
            return
        }

        blur.setValue(CIImage(image: image), forKey: kCIInputImageKey)
        blur.setValue(radius, forKey: kCIInputRadiusKey)

        let ciContext = CIContext(options: nil)

        guard let result = blur.value(forKey: kCIOutputImageKey) as? CIImage else { return }

        let boundingRect = CGRect(
            x: 0,
            y: 0,
            width: frame.width,
            height: frame.height
        )

        guard let cgImage = ciContext.createCGImage(result, from: boundingRect) else { return }

        let filteredImage = UIImage(cgImage: cgImage)

        let blurOverlay = BlurOverlay()
        blurOverlay.frame = boundingRect

        blurOverlay.image = filteredImage
        blurOverlay.contentMode = UIView.ContentMode.left

        if
            let superview = superview as? UIStackView,
            let index = (superview as UIStackView).arrangedSubviews.firstIndex(of: this)
        {
            removeFromSuperview()
            superview.insertArrangedSubview(blurOverlay, at: index)
        } else {
            blurOverlay.frame.origin = frame.origin

            UIView.transition(
                from: this,
                to: blurOverlay,
                duration: 0.2,
                options: UIView.AnimationOptions.curveEaseIn,
                completion: nil
            )
        }

        objc_setAssociatedObject(
            this,
            &BlurableKey.blurable,
            blurOverlay,
            objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN
        )
    }

    func unBlur() {
        guard
            let this = self as? UIView,
            let blurOverlay = objc_getAssociatedObject(self as? UIView ?? UIView(), &BlurableKey.blurable) as? BlurOverlay
        else {
            return
        }

        if
            let superview = blurOverlay.superview as? UIStackView,
            let index = (blurOverlay.superview as? UIStackView)?.arrangedSubviews.firstIndex(of: blurOverlay)
        {
            blurOverlay.removeFromSuperview()
            superview.insertArrangedSubview(this, at: index)
        } else {
            this.frame.origin = blurOverlay.frame.origin

            UIView.transition(
                from: blurOverlay,
                to: this,
                duration: 0.2,
                options: UIView.AnimationOptions.curveEaseIn,
                completion: nil
            )
        }

        objc_setAssociatedObject(
            this,
            &BlurableKey.blurable,
            nil,
            objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN
        )
    }

    var isBlurred: Bool {
        return objc_getAssociatedObject(self as? UIView ?? UIView(), &BlurableKey.blurable) is BlurOverlay
    }
}

extension UIView: Blurable {
    func add(subview: UIView) {
        addSubview(subview)
    }
}

class BlurOverlay: UIImageView {}

enum BlurableKey {
    static var blurable = "blurable"
}

// ===

/// VisualEffectView is a dynamic background blur view.
open class VisualEffectView: UIVisualEffectView {
    /// Returns the instance of UIBlurEffect.
    private let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()

    /**
     Tint color.

     The default value is nil.
     */
    open var colorTint: UIColor? {
        get {
            if #available(iOS 14, *) {
                return ios14_colorTint
            } else {
                return _value(forKey: .colorTint)
            }
        }
        set {
            if #available(iOS 14, *) {
                ios14_colorTint = newValue
            } else {
                _setValue(newValue, forKey: .colorTint)
            }
        }
    }

    /**
     Tint color alpha.

     Don't use it unless `colorTint` is not nil.
     The default value is 0.0.
     */
    open var colorTintAlpha: CGFloat {
        get { return _value(forKey: .colorTintAlpha) ?? 0.0 }
        set {
            if #available(iOS 14, *) {
                ios14_colorTint = ios14_colorTint?.withAlphaComponent(newValue)
            } else {
                _setValue(newValue, forKey: .colorTintAlpha)
            }
        }
    }

    /**
     Blur radius.

     The default value is 0.0.
     */
    open var blurRadius: CGFloat {
        get {
            if #available(iOS 14, *) {
                return ios14_blurRadius
            } else {
                return _value(forKey: .blurRadius) ?? 0.0
            }
        }
        set {
            if #available(iOS 14, *) {
                ios14_blurRadius = newValue
            } else {
                _setValue(newValue, forKey: .blurRadius)
            }
        }
    }

    /**
     Scale factor.

     The scale factor determines how content in the view is mapped from the logical coordinate space (measured in points) to the device coordinate space (measured in pixels).

     The default value is 1.0.
     */
    open var scale: CGFloat {
        get { return _value(forKey: .scale) ?? 1.0 }
        set { _setValue(newValue, forKey: .scale) }
    }

    // MARK: - Initialization

    override public init(effect: UIVisualEffect?) {
        super.init(effect: effect)

        self.scale = 1
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.scale = 1
    }
}

// MARK: - Helpers

private extension VisualEffectView {
    /// Returns the value for the key on the blurEffect.
    func _value<T>(forKey key: Key) -> T? {
        return blurEffect.value(forKeyPath: key.rawValue) as? T
    }

    /// Sets the value for the key on the blurEffect.
    func _setValue<T>(_ value: T?, forKey key: Key) {
        blurEffect.setValue(value, forKeyPath: key.rawValue)
        if #available(iOS 14, *) {} else {
            effect = blurEffect
        }
    }

    enum Key: String {
        case colorTint, colorTintAlpha, blurRadius, scale
    }
}

// ["grayscaleTintLevel", "grayscaleTintAlpha", "lightenGrayscaleWithSourceOver", "colorTint", "colorTintAlpha", "colorBurnTintLevel", "colorBurnTintAlpha", "darkeningTintAlpha", "darkeningTintHue", "darkeningTintSaturation", "darkenWithSourceOver", "blurRadius", "saturationDeltaFactor", "scale", "zoom"]

// ==

@available(iOS 14, *)
extension UIVisualEffectView {
    var ios14_blurRadius: CGFloat {
        get {
            return gaussianBlur?.requestedValues?["inputRadius"] as? CGFloat ?? 0
        }
        set {
            prepareForChanges()
            gaussianBlur?.requestedValues?["inputRadius"] = newValue
            applyChanges()
        }
    }
    var ios14_colorTint: UIColor? {
        get {
            return sourceOver?.value(forKeyPath: "color") as? UIColor
        }
        set {
            prepareForChanges()
            sourceOver?.setValue(newValue, forKeyPath: "color")
            sourceOver?.perform(Selector(("applyRequestedEffectToView:")), with: overlayView)
            applyChanges()
        }
    }
}

private extension UIVisualEffectView {
    var backdropView: UIView? {
        return subview(of: NSClassFromString("_UIVisualEffectBackdropView"))
    }
    var overlayView: UIView? {
        return subview(of: NSClassFromString("_UIVisualEffectSubview"))
    }
    var gaussianBlur: NSObject? {
        return backdropView?.value(forKey: "filters", withFilterType: "gaussianBlur")
    }
    var sourceOver: NSObject? {
        return overlayView?.value(forKey: "viewEffects", withFilterType: "sourceOver")
    }
    func prepareForChanges() {
        self.effect = UIBlurEffect(style: .light)
        gaussianBlur?.setValue(1.0, forKeyPath: "requestedScaleHint")
    }
    func applyChanges() {
        backdropView?.perform(Selector(("applyRequestedFilterEffects")))
    }
}

private extension NSObject {
    var requestedValues: [String: Any]? {
        get { return value(forKeyPath: "requestedValues") as? [String: Any] }
        set { setValue(newValue, forKeyPath: "requestedValues") }
    }
    func value(forKey key: String, withFilterType filterType: String) -> NSObject? {
        return (value(forKeyPath: key) as? [NSObject])?.first { $0.value(forKeyPath: "filterType") as? String == filterType }
    }
}

private extension UIView {
    func subview(of classType: AnyClass?) -> UIView? {
        return subviews.first { type(of: $0) == classType }
    }
}
