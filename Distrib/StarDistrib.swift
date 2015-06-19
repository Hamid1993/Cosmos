//
// Star rating control written in Swift for iOS.
//
// https://github.com/exchangegroup/Star
//
// This file was automatically generated by combining multiple Swift source files.
//


// ----------------------------
//
// StarFillMode.swift
//
// ----------------------------

import Foundation

/**

Defines how the star is filled when the rating is not an integer number. For example, if rating is 4.6 and the fill more is Half, the star will appear to be half filled.

*/
public enum StarFillMode: Int {
  /// Show only fully filled stars. For example, fourth star will be empty for 3.2.
  case Full = 0
  
  /// Show fully filled and half-filled stars. For example, fourth star will be half filled for 3.6.
  case Half = 1
  
  /// Fill star according to decimal rating. For example, fourth star will be 20% filled for 3.2. By default the fill rate is not applied linearly but corrected (see correctFillLevelForPreciseMode setting).
  case Precise = 2
}


// ----------------------------
//
// StarLayer.swift
//
// ----------------------------

/**

Draws a star inside a layer

*/
struct StarLayer {
  /**
  
  Creates a square layer with given size and draws the star shape in it.
  
  - parameter starPoints: Array of points for drawing a closed shape. The size of enclosing rectangle is 100 by 100.
  
  - parameter size: The width and height of the layer. The star shape is scaled to fill the size of the layer.
  
  - parameter lineWidth: The width of the star stroke.
  
  - parameter fillColor: Star shape fill color. Fill color is invisible if it is a clear color.
  
  - parameter strokeColor: Star shape stroke color. Stroke is invisible if it is a clear color.
  
  - returns: New layer containing the star shape.
  
  */
  static func create(starPoints: [CGPoint], size: Double,
    lineWidth: Double, fillColor: UIColor, strokeColor: UIColor) -> CALayer {
      
    let containerLayer = createContainerLayer(size)
    let path = createStarPath(starPoints, size: size)
      
    let shapeLayer = createShapeLayer(path.CGPath, lineWidth: lineWidth,
      fillColor: fillColor, strokeColor: strokeColor)
      
    let maskLayer = createMaskLayer(path.CGPath)
    
    containerLayer.mask = maskLayer
    containerLayer.addSublayer(shapeLayer)
    
    return containerLayer
  }
  
  /**
  
  Creates a mask layer with the given path shape. The purpose of the mask layer is to prevent the shape's stroke to go over the shape's edges.
  
  - parameter path: The star shape path.
  
  - returns: New mask layer.

  */
  static func createMaskLayer(path: CGPath) -> CALayer {
    let layer = CAShapeLayer()
    layer.anchorPoint = CGPoint()
    layer.contentsScale = UIScreen.mainScreen().scale
    layer.path = path
    return layer
  }
  
  /**
  
  Creates the star shape layer.
  
  - parameter path: The star shape path.
  
  - parameter lineWidth: The width of the star stroke.
  
  - parameter fillColor: Star shape fill color. Fill color is invisible if it is a clear color.
  
  - parameter strokeColor: Star shape stroke color. Stroke is invisible if it is a clear color.
  
  - returns: New shape layer.
  
  */
  static func createShapeLayer(path: CGPath, lineWidth: Double, fillColor: UIColor, strokeColor: UIColor) -> CALayer {
    let layer = CAShapeLayer()
    layer.anchorPoint = CGPoint()
    layer.contentsScale = UIScreen.mainScreen().scale
    layer.strokeColor = strokeColor.CGColor
    layer.fillColor = fillColor.CGColor
    layer.lineWidth = CGFloat(lineWidth)
    layer.path = path
    return layer
  }
  
  /**
  
  Creates a layer that will contain the shape layer.
  
  - returns: New container layer.
  
  */
  static func createContainerLayer(size: Double) -> CALayer {
    let layer = CALayer()
    layer.contentsScale = UIScreen.mainScreen().scale
    layer.anchorPoint = CGPoint()
    layer.masksToBounds = true
    layer.bounds.size = CGSize(width: size, height: size)
    return layer
  }
  
  /**
  
  Creates a path for the given star points and size. The star points specify a shape of size 100 by 100. The star shape will be scaled if the size parameter is not 100. For exampe, if size parameter is 200 the shape will be scaled by 2.
  
  - parameter starPoints: Array of points for drawing a closed shape. The size of enclosing rectangle is 100 by 100.
  
  - parameter size: Specifies the size of the shape to return.
  
  - returns: New shape path.
  
  */
  static func createStarPath(starPoints: [CGPoint], size: Double) -> UIBezierPath {
    let points = scaleStar(starPoints, factor: size / 100)
    let path = UIBezierPath()
    path.moveToPoint(points[0])
    let remainingPoints = Array(points[1..<points.count])
    
    for point in remainingPoints {
      path.addLineToPoint(point)
    }
    
    path.closePath()
    return path
  }
  
  /**
  
  Scale the star points by the given factor.
  
  - parameter starPoints: Array of points for drawing a closed shape. The size of enclosing rectangle is 100 by 100.  
  
  - parameter factor: The factor by which the star points are scaled. For example, if it is 0.5 the output points will define the shape twice as small as the original.
  
  - returns: The scaled shape.
  
  */
  static func scaleStar(starPoints: [CGPoint], factor: Double) -> [CGPoint] {
    return starPoints.map { point in
      return CGPoint(x: point.x * CGFloat(factor), y: point.y * CGFloat(factor))
    }
  }
}


// ----------------------------
//
// StarRating.swift
//
// ----------------------------

import UIKit


/**

Colection of helper functions for creating star layers.

*/
class StarRating {
  /**
  
  Creates the layers for the stars.
  
  - parameter rating: The decimal number representing the rating. Usually a number between 1 and 5
  - parameter settings: Star view settings.
  - returns: Array of star layers.
  
  */
  class func createStarLayers(rating: Double, settings: StarRatingSettings) -> [CALayer] {

    var ratingRemander = numberOfFilledStars(rating, totalNumberOfStars: settings.totalStars)

    var starLayers = [CALayer]()

    for _ in (0..<settings.totalStars) {
      let fillLevel = starFillLevel(ratingRemainder: ratingRemander,
        fillMode: settings.fillMode,
        fillCorrection: settings.fillCorrection)

      let starLayer = createCompositeStarLayer(fillLevel, settings: settings)
      starLayers.append(starLayer)
      ratingRemander--
    }

    positionStarLayers(starLayers, marginBetweenStars: settings.marginBetweenStars)
    return starLayers
  }

  
  /**
  
  Creates an layer that shows a star that can look empty, fully filled or partially filled.
  Partially filled layer contains two sublayers.
  
  - parameter starFillLevel: Decimal number between 0 and 1 describing the star fill level.
  - parameter settings: Star view settings.
  - returns: Layer that shows the star. The layer is displauyed in the star view.
  
  */
  class func createCompositeStarLayer(starFillLevel: Double, settings: StarRatingSettings) -> CALayer {

    if starFillLevel >= 1 {
      return createStarLayer(true, settings: settings)
    }

    if starFillLevel == 0 {
      return createStarLayer(false, settings: settings)
    }

    return createPartialStar(starFillLevel, settings: settings)
  }

  /**
  
  Creates a partially filled star layer with two sub-layers:
  
  1. The layer for the 'filled star' character on top. The fill level parameter determines the width of this layer.
  2. The layer for the 'empty star' character below.
  
  
  - parameter starFillLevel: Decimal number between 0 and 1 describing the star fill level.
  - parameter settings: Star view settings.

  - returns: Layer that contains the partially filled star.
  
  */
  class func createPartialStar(starFillLevel: Double, settings: StarRatingSettings) -> CALayer {
    let filledStar = createStarLayer(true, settings: settings)
    let emptyStar = createStarLayer(false, settings: settings)

    let parentLayer = CALayer()
    parentLayer.contentsScale = UIScreen.mainScreen().scale
    parentLayer.bounds = CGRect(origin: CGPoint(), size: filledStar.bounds.size)
    parentLayer.anchorPoint = CGPoint()
    parentLayer.addSublayer(emptyStar)
    parentLayer.addSublayer(filledStar)

    // make filled layer width smaller according to the fill level.
    filledStar.bounds.size.width *= CGFloat(starFillLevel)

    return parentLayer
  }

  /**

  Returns a decimal number between 0 and 1 describing the star fill level.
  
  - parameter ratingRemainder: This value is passed from the loop that creates star layers. The value starts with the rating value and decremented by 1 when each star is created. For example, suppose we want to display rating of 3.5. When the first star is created the ratingRemainder parameter will be 3.5. For the second star it will be 2.5. Third: 1.5. Fourth: 0.5. Fifth: -0.5.
  
  - parameter fillMode: Describe how stars should be filled: full, half or precise.
  
  - parameter fillCorrection: Value between 0 and 100 that is used to correct the star fill value when precise fill mode is used. Default value is 40. When 0 - no correction is applied. Correction is done to compensate for the fact that star characters do not fill the full width of they lay rectangle. Default value is 40.
  
  - returns: Decimal value between 0 and 1 describing the star fill level. 1 is a fully filled star. 0 is an empty star. 0.5 is a half-star.

  */
  class func starFillLevel(ratingRemainder ratingRemainder: Double, fillMode: StarFillMode,
    fillCorrection: Double) -> Double {
      
    var result = ratingRemainder
    
    if result > 1 { result = 1 }
    if result < 0 { result = 0 }
      
    switch fillMode {
    case .Full:
       result = Double(round(result))
    case .Half:
      result = Double(round(result * 2) / 2)
    case .Precise :
      result = correctPreciseFillLevel(result, fillCorrection: fillCorrection)
    }
    
    return result
  }

  /**

  Correct the fill level to achieve more gradual fill of the ★ and ☆ star characters in precise mode. This is done to compensate for the fact that the ★ and ☆ characters do not occupy 100% width of their layer bound rectangle.
  
  Graph: https://www.desmos.com/calculator/gk0fpc7tun
  
  - parameter fillLevel: The initial fill level for correction.
  
  - parameter fillCorrection: Value between 0 and 100 that is used to correct the star fill value when precise fill mode is used. Default value is 40. When 0 - no correction is applied. Correction is done to compensate for the fact that star characters do not fill the full width of they lay rectangle. Default value is 40.
  
  - returns: The corrected fill level.

  */
  class func correctPreciseFillLevel(fillLevel: Double, fillCorrection: Double) -> Double {
  
    var result = fillLevel
    
    if result > 1 { result = 1 }
    if result < 0 { result = 0 }
    
    let correctionRatio: Double = fillCorrection / 200
    
    let multiplier: Double = 1 - 2 * correctionRatio
    
    return multiplier * result + correctionRatio
  }

  private class func createStarLayer(isFilled: Bool, settings: StarRatingSettings) -> CALayer {
    let fillColor = isFilled ? settings.colorFilled : UIColor.clearColor()
    let strokeColor = isFilled ? UIColor.clearColor() : settings.colorEmpty

    return StarLayer.create(settings.starPoints,
      size: settings.starSize,
      lineWidth: 1,
      fillColor: fillColor,
      strokeColor: strokeColor)
  }

  /**
  
  Returns the number of filled stars for given rating.
  
  - parameter rating: The rating to be displayed.
  - parameter maxNumberOfStars: Total number of stars.
  - returns: Number of filled stars. If rating is biggen than the total number of stars (usually 5) it returns the maximum number of stars.
  
  */
  class func numberOfFilledStars(rating: Double, totalNumberOfStars: Int) -> Double {
    if rating > Double(totalNumberOfStars) { return Double(totalNumberOfStars) }
    if rating < 0 { return 0 }

    return rating
  }

  /**
  
  Positions the star layers one after another with a margin in between.
  
  - parameter layers: The star layers array.
  - parameter marginBetweenStars: Margin between stars.

  */
  class func positionStarLayers(layers: [CALayer], marginBetweenStars: CGFloat) {
    var positionX:CGFloat = 0

    for layer in layers {
      layer.position.x = positionX
      positionX += layer.bounds.width + marginBetweenStars
    }
  }
}


// ----------------------------
//
// StarRatingDefaultSettings.swift
//
// ----------------------------


/**

Defaults setting values.

*/
struct StarRatingDefaultSettings {
  init() {}
  
  /// Raiting value that is shown in the storyboard by default.
  static let rating: Double = 3.5
  
  /// The total number of start to be shown.
  static let totalStars = 5
  
  /**
  
  Defines how the star should appear to be filled when the rating value is not an integer value.
  
  */
  static let fillMode = StarFillMode.Half
  
  /// Distance between stars expressed. The value is automatically calculated based on marginBetweenStarsRelativeToFontSize property and the font size.
  static let marginBetweenStars: CGFloat = 0
  
  /**
  
  Distance between stars expressed as a percentage of the font size. For example, if the font size is 12 and the value is 25 the distance will be 3.
  
  */
  static let marginPercent: Double = 10
  
  /// The font used to draw the star character
  static let starFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
  
  /// Size of the star.
  static var starSize: Double = 20
  
  /// Character used to show a filled star
  static let textFilled = "★"
  
  /// Character used to show an empty star
  static let textEmpty = "☆"
  
  /// Filled star color
  static let colorFilled = UIColor(red: 1, green: 149/255, blue: 0, alpha: 1)
  
  /// Empty star color
  static let colorEmpty = UIColor(red: 1, green: 149/255, blue: 0, alpha: 1)
  
  /// Font for the text
  static let textFont = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
  
  /// Color of the text
  static let textColor = UIColor.grayColor()
  
  /// Distance between the text and the star. The value is automatically calculated based on marginBetweenStarsAndTextRelativeToFontSize property and the font size.
  static let marginBetweenStarsAndText: CGFloat = 0
  
  /**
  
  Distance between the text and the star expressed as a percentage of the font size. For example, if the font size is 12 and the value is 25 the margin will be 3.
  
  */
  static let textMarginPercent: Double = 25
  
  /**
  
  Value between 0 and 100 that is used to correct the star fill value when precise fill mode is used. Default value is 40. When 0 - no correction is applied. Correction is done to compensate for the fact that star characters do not fill the full width of they lay rectangle. Default value is 40.
  
  Graph: https://www.desmos.com/calculator/gk0fpc7tun
  
  */
  static let fillCorrection: Double = 40
  
  
  /**
  
  Points for drawing the star. Size is 100 by 100 pixels. Supply your points if you need to draw a different shape.
  
  */
  static let starPoints: [CGPoint] = [
    CGPoint(x: 49.5,  y: 0.0),
    CGPoint(x: 60.5,  y: 35.0),
    CGPoint(x: 99.0, y: 35.0),
    CGPoint(x: 67.5,  y: 58.0),
    CGPoint(x: 78.5,  y: 92.0),
    CGPoint(x: 49.5,    y: 71.0),
    CGPoint(x: 20.5,  y: 92.0),
    CGPoint(x: 31.5,  y: 58.0),
    CGPoint(x: 0.0,   y: 35.0),
    CGPoint(x: 38.5,  y: 35.0)
  ]
}


// ----------------------------
//
// StarRatingLayerHelper.swift
//
// ----------------------------

import UIKit

/// Helper class for creating CALayer objects.
class StarRatingLayerHelper {
  /**

  Creates a text layer for the given text string and font.
  
  - parameter text: The text shown in the layer.
  - parameter font: The text font. It is also used to calculate the layer bounds.
  - parameter color: Text color.
  
  - returns: New text layer.
  
  */
  class func createTextLayer(text: String, font: UIFont, color: UIColor) -> CATextLayer {
    let size = NSString(string: text).sizeWithAttributes([NSFontAttributeName: font])
    
    let layer = CATextLayer()
    layer.bounds = CGRect(origin: CGPoint(), size: size)
    layer.anchorPoint = CGPoint()
    
    layer.string = text
    layer.font = CGFontCreateWithFontName(font.fontName)
    layer.fontSize = font.pointSize
    layer.foregroundColor = color.CGColor
    layer.contentsScale = UIScreen.mainScreen().scale
    
    return layer
  }
}


// ----------------------------
//
// StarRatingSettings.swift
//
// ----------------------------

import UIKit

/**

Settings that define the appearance of the star rating views.

*/
public struct StarRatingSettings {
  init() {}
  
  /// Raiting value that is shown in the storyboard by default.
  public var rating: Double = StarRatingDefaultSettings.rating
  
  /// Text that is shown in the storyboard.
  public var text: String?
  
  /// The maximum number of start to be shown.
  public var totalStars = StarRatingDefaultSettings.totalStars
  
  /**

  Defines how the star should appear to be filled when the rating value is not an integer value.

  */
  public var fillMode = StarRatingDefaultSettings.fillMode
  
  /// Distance between stars expressed. The value is automatically calculated based on marginPercent property and the font size.
  var marginBetweenStars:CGFloat = 0
  
  /**

  Distance between stars expressed as a percentage of the font size. For example, if the font size is 12 and the value is 25 the distance will be 3.

  */
  public var marginPercent: Double = StarRatingDefaultSettings.marginPercent
  
  /// The font used to draw the star character
  public var starFont = StarRatingDefaultSettings.starFont
  
  /// Size of the star.
  public var starSize: Double = StarRatingDefaultSettings.starSize
  
  /// Character used to show a filled star
  public var textFilled = StarRatingDefaultSettings.textFilled
  
  /// Character used to show an empty star
  public var textEmpty = StarRatingDefaultSettings.textEmpty
  
  /// Filled star color
  public var colorFilled = StarRatingDefaultSettings.colorFilled
  
  /// Empty star color
  public var colorEmpty = StarRatingDefaultSettings.colorEmpty
  
  /// Font for the text
  public var textFont = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
  
  /// Color of the text
  public var textColor = StarRatingDefaultSettings.textColor
  
  /// Distance between the text and the star. The value is automatically calculated based on textMarginPercent property and the font size.
  var marginBetweenStarsAndText: CGFloat = 0
  
  /**

  Distance between the text and the star expressed as a percentage of the font size. For example, if the font size is 12 and the value is 25 the margin will be 3.

  */
  public var textMarginPercent: Double = StarRatingDefaultSettings.textMarginPercent
  
  /**
  
  Value between 0 and 100 that is used to correct the star fill value when precise fill mode is used. Default value is 40. When 0 - no correction is applied. Correction is done to compensate for the fact that star characters do not fill the full width of they lay rectangle. Default value is 40.
  
  Graph: https://www.desmos.com/calculator/gk0fpc7tun
  
  */
  public var fillCorrection: Double = StarRatingDefaultSettings.fillCorrection
  
  /**
  
  Points for drawing the star. Size is 100 by 100 pixels. Supply your points if you need to draw a different shape.
  
  */
  public var starPoints: [CGPoint] = StarRatingDefaultSettings.starPoints
}


// ----------------------------
//
// StarRatingSize.swift
//
// ----------------------------

import UIKit

/**

Helper class for calculating size fo star view.

*/
class StarRatingSize {
  /**
  
  Calculates the size of star rating view. It goes through all the layers and makes size the view size is large enough to show all of them.
  
  */
  class func calculateSizeToFitLayers(layers: [CALayer]) -> CGSize {
    var size = CGSize()
    
    for layer in layers {
      if layer.frame.maxX > size.width {
        size.width = layer.frame.maxX
      }
      
      if layer.frame.maxY > size.height {
        size.height = layer.frame.maxY
      }
    }
    
    return size
  }
}


// ----------------------------
//
// StarRatingText.swift
//
// ----------------------------



import UIKit

/**

Positions the text layer to the right of the stars.

*/
class StarRatingText {
  /**
  
  Positions the text layer to the right from the stars. Text is aligned to the center of the star superview vertically.
  
  - parameter layer: The text layer to be positioned.
  - parameter starsSize: The size of the star superview.
  - parameter marginBetweenStarsAndText: The distance between the stars and the text.
  
  */
  class func position(layer: CALayer, starsSize: CGSize, marginBetweenStarsAndText: CGFloat) {
    layer.position.x = starsSize.width + marginBetweenStarsAndText
    let yOffset = (starsSize.height - layer.bounds.height) / 2
    layer.position.y = yOffset
  }
}


// ----------------------------
//
// StarRatingView.swift
//
// ----------------------------

import UIKit

/*

A star rating view that can be used to show customer rating for the products. An optional text can be supplied that is shown to the right from the stars.

Example:

   ratingView.show(rating: 4, text: "(132)")

Displays: ★★★★☆ (132)

*/
@IBDesignable public class StarRatingView: UIView {
  // MARK: Inspectable properties for storyboard
  
  @IBInspectable var rating: Double = StarRatingDefaultSettings.rating {
    didSet { settings.rating = rating }
  }
  
  @IBInspectable var totalStars: Int = StarRatingDefaultSettings.totalStars {
    didSet { settings.totalStars = totalStars }
  }
  
  @IBInspectable var textFilled: String = StarRatingDefaultSettings.textFilled {
    didSet { settings.textFilled = textFilled }
  }
  
  @IBInspectable var textEmpty: String = StarRatingDefaultSettings.textEmpty {
    didSet { settings.textEmpty = textEmpty }
  }
  
  @IBInspectable var starSize: Double = StarRatingDefaultSettings.starSize {
    didSet {
      settings.starSize = starSize
    }
  }
  
  @IBInspectable var colorFilled: UIColor = StarRatingDefaultSettings.colorFilled {
    didSet { settings.colorFilled = colorFilled }
  }
  
  @IBInspectable var colorEmpty: UIColor = StarRatingDefaultSettings.colorEmpty {
    didSet { settings.colorEmpty = colorEmpty }
  }
  
  @IBInspectable var marginPercent: Double = StarRatingDefaultSettings.marginPercent {
    didSet { settings.marginPercent = marginPercent }
  }
  
  @IBInspectable var fillMode: Int = StarRatingDefaultSettings.fillMode.rawValue {
    didSet {
      settings.fillMode = StarFillMode(rawValue: fillMode) ?? StarRatingDefaultSettings.fillMode
    }
  }
  
  @IBInspectable var fillCorrection: Double = StarRatingDefaultSettings.fillCorrection {
    didSet {
      settings.fillCorrection = min( max(fillCorrection, 0) , 100)
    }
  }
  
  @IBInspectable var text: String? {
    didSet { settings.text = text }
    
  }
  
  @IBInspectable var textMarginPercent: Double = StarRatingDefaultSettings.textMarginPercent {
    didSet { settings.textMarginPercent = textMarginPercent }

  }
  
  @IBInspectable var textColor: UIColor = StarRatingDefaultSettings.textColor {
    didSet { settings.textColor = textColor }
  }
  
  
  public override func prepareForInterfaceBuilder() {
    super.prepareForInterfaceBuilder()
    
    show(rating: settings.rating, text: settings.text)
  }
  
  /// Star rating settings.
  public var settings = StarRatingSettings()
  
  /// Stores the size of the view. It is used as intrinsic content size.
  private var viewSize = CGSize()

  /**
  
  Creates sub-layers in the view that show the stars and the optional text.
  
  Example:
  
      ratingView.show(rating: 4.3, text: "(132)")
  
  - parameter rating: Number of stars to be shown, usually between 1 and 5. If the value is decimal the stars will be shown according to the Fill Mode setting.
  - parameter text: An optional text string that will be shown to the right from the stars.
  
  */
  public func show(rating rating: Double, text: String? = nil) {
    
    let currenText = text ?? settings.text
    
    calculateMargins()
    
    // Create star layers
    // ------------
    
    var layers = StarRating.createStarLayers(rating, settings: settings)
    layer.sublayers = layers
    
    // Create text layer
    // ------------

    if let currenText = currenText {
      let textLayer = createTextLayer(currenText, layers: layers)
      layers.append(textLayer)
    }
    
    // Update size
    // ------------

    updateSize(layers)
  }
  
  
  
  /**
  
  Creates the text layer for the given text string.
  
  - parameter text: Text string for the text layer.
  - parameter layers: Arrays of layers containing the stars.
  
  - returns: The newly created text layer.
  
  */
  private func createTextLayer(text: String, layers: [CALayer]) -> CALayer {
    let textLayer = StarRatingLayerHelper.createTextLayer(text,
      font: settings.textFont, color: settings.textColor)
    
    let starsSize = StarRatingSize.calculateSizeToFitLayers(layers)
    
    StarRatingText.position(textLayer, starsSize: starsSize,
      marginBetweenStarsAndText: settings.marginBetweenStarsAndText)
    
    layer.addSublayer(textLayer)
    
    return textLayer
  }
  
  /**

  Updates the size to fit all the layers containing stars and text.
  
  - parameter layers: Array of layers containing stars and the text.

  */
  private func updateSize(layers: [CALayer]) {
    viewSize = StarRatingSize.calculateSizeToFitLayers(layers)
    invalidateIntrinsicContentSize()
  }
  
  /// Calculate margins based on the font size.
  private func calculateMargins() {
    print("!!!!!!!!!! star font size \(settings.starFont.pointSize)")
    settings.marginBetweenStars = settings.starFont.pointSize *
      CGFloat(settings.marginPercent / 100)
    
    settings.marginBetweenStarsAndText = settings.textFont.pointSize *
      CGFloat(settings.textMarginPercent / 100)
  }
  
  /// Returns the content size to fit all the star and text layers.
  override public func intrinsicContentSize() -> CGSize {
    return viewSize
  }
}


