import UIKit
import PureLayout

class ShopView : UIView {

    let pricePanelHeight : CGFloat = 170
    let shopPanelHeight : CGFloat = 200
    
    var controller : ViewController?
    
    var shopPanel = UIView()
    var pricePanel = UIView()
    
    var priceLabel = UILabel()
    var productName = UILabel()
    var filterLabel = UILabel()
    var rimCollectionLabel = UILabel()
    var closeButton = UIButton()
    var favoriteButton = UIButton()
    var shareButton = UIButton()
    
    var rims = [UIImageView]()
    var rimsOffset = [NSLayoutConstraint]()
    
    var shopPanelY : NSLayoutConstraint?
    var pricePanelY : NSLayoutConstraint?
    
    var closeGesture : UITapGestureRecognizer?
    var shareGesture : UITapGestureRecognizer?
    var favoriteGesture : UITapGestureRecognizer?
    var rim1Gesture : UITapGestureRecognizer?
    var rim2Gesture : UITapGestureRecognizer?
    var rim3Gesture : UITapGestureRecognizer?
    
    var currentRimId = 0
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    func setupView() {
        setupGestures()
        
        pricePanel.backgroundColor = UIColor(red: 114, green: 75, blue: 139)
        pricePanel.layer.cornerRadius = 40
        pricePanel.layer.maskedCorners = [.layerMinXMinYCorner]
        addSubview(pricePanel)
        
        favoriteButton.setImage(UIImage(named: "ic_heart"), for: .normal)
        favoriteButton.contentMode = .scaleAspectFit
        favoriteButton.addGestureRecognizer(favoriteGesture!)
        pricePanel.addSubview(favoriteButton)
        
        shareButton.setImage(UIImage(named: "ic_share"), for: .normal)
        shareButton.contentMode = .scaleAspectFit
        shareButton.addGestureRecognizer(favoriteGesture!)
        pricePanel.addSubview(shareButton)
        
        priceLabel.textColor = .white
        priceLabel.text = "$1,099"
        priceLabel.font = UIFont.systemFont(ofSize: 34, weight: .thin)
        pricePanel.addSubview(priceLabel)
        
        productName.textColor = .white
        productName.text = "AX195 Cornice"
        productName.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        pricePanel.addSubview(productName)
        
        shopPanel.backgroundColor = .white
        shopPanel.layer.cornerRadius = 40
        shopPanel.layer.maskedCorners = [.layerMinXMinYCorner]
        addSubview(shopPanel)
        
        filterLabel.textColor = .gray
        filterLabel.text = "All (3)"
        filterLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        shopPanel.addSubview(filterLabel)
        
        rimCollectionLabel.textColor = .black
        rimCollectionLabel.text = "ATX collection"
        rimCollectionLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        shopPanel.addSubview(rimCollectionLabel)
        
        closeButton.setImage(UIImage(named: "ic_cross"), for: .normal)
        closeButton.contentMode = .scaleAspectFit
        closeButton.addGestureRecognizer(closeGesture!)
        shopPanel.addSubview(closeButton)
        
        for index in 1...3 {
            let rim = UIImageView(image: UIImage(named: "ic_rim\(index)"))
            rim.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
            rim.layer.borderWidth = 1
            rim.layer.cornerRadius = 10
            rim.isUserInteractionEnabled = true
            rims.append(rim)
            rimsOffset.append(NSLayoutConstraint())
        }
        
        rims[0].addGestureRecognizer(rim1Gesture!)
        shopPanel.addSubview(rims[0])
        
        rims[1].addGestureRecognizer(rim2Gesture!)
        shopPanel.addSubview(rims[1])
        
        rims[2].addGestureRecognizer(rim3Gesture!)
        shopPanel.addSubview(rims[2])
        
        // constraints
        
        shopPanelY = shopPanel.autoPinEdge(toSuperviewEdge: .bottom, withInset: -shopPanelHeight)
        shopPanel.autoPinEdge(toSuperviewEdge: .left)
        shopPanel.autoPinEdge(toSuperviewEdge: .right)
        shopPanel.autoSetDimension(.height, toSize: shopPanelHeight)
        
        pricePanelY = pricePanel.autoPinEdge(.top, to: .top, of: shopPanel)
        pricePanel.autoPinEdge(toSuperviewEdge: .left)
        pricePanel.autoPinEdge(toSuperviewEdge: .right)
        pricePanel.autoSetDimension(.height, toSize: pricePanelHeight)
        
        closeButton.autoSetDimensions(to: CGSize(width: 15, height: 15))
        closeButton.autoPinEdge(toSuperviewEdge: .right, withInset: 15)
        closeButton.autoPinEdge(toSuperviewEdge: .top, withInset: 15)
        
        shareButton.autoPinEdge(toSuperviewEdge: .right, withInset: 30)
        shareButton.autoSetDimensions(to: CGSize(width: 15, height: 15))
        shareButton.autoPinEdge(.bottom, to: .top, of: favoriteButton, withOffset: -15)
        
        favoriteButton.autoPinEdge(toSuperviewEdge: .right, withInset: 30)
        favoriteButton.autoSetDimensions(to: CGSize(width: 15, height: 15))
        favoriteButton.autoPinEdge(toSuperviewEdge: .top, withInset: 60)
        
        priceLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 40)
        priceLabel.autoPinEdge(.top, to: .top, of: shareButton)
        
        productName.autoPinEdge(.top, to: .bottom, of: priceLabel, withOffset: 4)
        productName.autoPinEdge(.left, to: .left, of: priceLabel)
        
        filterLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 50)
        filterLabel.autoAlignAxis(.horizontal, toSameAxisOf: closeButton)
        
        rimCollectionLabel.autoPinEdge(.left, to: .left, of: filterLabel)
        rimCollectionLabel.autoPinEdge(.top, to: .bottom, of: filterLabel, withOffset: 8)
        
        rims[0].autoSetDimensions(to: CGSize(width: 60, height: 60))
        rimsOffset[0] = rims[0].autoPinEdge(toSuperviewEdge: .bottom, withInset: 50 + 15)
        rims[0].autoPinEdge(toSuperviewEdge: .left, withInset: 30)
        
        rims[1].autoSetDimensions(to: CGSize(width: 60, height: 60))
        rimsOffset[1] = rims[1].autoPinEdge(toSuperviewEdge: .bottom, withInset: 50)
        rims[1].autoPinEdge(.left, to: .right, of: rims[0], withOffset: 15)
        
        rims[2].autoSetDimensions(to: CGSize(width: 60, height: 60))
        rimsOffset[2] = rims[2].autoPinEdge(toSuperviewEdge: .bottom, withInset: 50)
        rims[2].autoPinEdge(.left, to: .right, of: rims[1], withOffset: 15)
    }
    
    func setupGestures() {
        closeGesture = UITapGestureRecognizer(target: self, action: #selector(hideAction))
        shareGesture = UITapGestureRecognizer(target: self, action: #selector(shareAction))
        favoriteGesture = UITapGestureRecognizer(target: self, action: #selector(favoriteAction))
        
        rim1Gesture = UITapGestureRecognizer(target: self, action: #selector(rim1Action))
        rim2Gesture = UITapGestureRecognizer(target: self, action: #selector(rim2Action))
        rim3Gesture = UITapGestureRecognizer(target: self, action: #selector(rim3Action))
    }
    
    // MARK : actions
    
    @objc func hideAction(recognizer: UITapGestureRecognizer) {
        hidePanel()
    }
    
    @objc func shareAction(recognizer: UITapGestureRecognizer) {
        
    }
    
    @objc func favoriteAction(recognizer: UITapGestureRecognizer) {
        
    }
    
    @objc func rim1Action(recognizer: UITapGestureRecognizer) {
        priceLabel.text = "$1,099"
        productName.text = "AX195 Cornice"
        controller?.switchRim(atId: 0)
        animateItemsList(targetId: 0)
    }
    
    @objc func rim2Action(recognizer: UITapGestureRecognizer) {
        priceLabel.text = "$599"
        productName.text = "AX200"
        controller?.switchRim(atId: 1)
        animateItemsList(targetId: 1)
    }
    
    @objc func rim3Action(recognizer: UITapGestureRecognizer) {
        priceLabel.text = "$899"
        productName.text = "AX188 Ledge"
        controller?.switchRim(atId: 2)
        animateItemsList(targetId: 2)
    }
    
    // MARK : animations
    
    func showPanel() {
        UIView.animate(withDuration: 0.3, animations: {
            self.shopPanelY?.constant = 0
            self.layoutIfNeeded()
        }, completion: { finished in
            UIView.animate(withDuration: 0.1, animations: {
                self.shopPanelY?.constant = 10
                self.layoutIfNeeded()
                self.closeButton.isUserInteractionEnabled = true
            }, completion: { finished in
                UIView.animate(withDuration: 0.3, animations: {
                    self.pricePanelY?.constant = -self.pricePanelHeight + 40
                    self.layoutIfNeeded()
                }, completion: { finished in
                    UIView.animate(withDuration: 0.1, animations: {
                        self.pricePanelY?.constant = -self.pricePanelHeight + 60
                        self.layoutIfNeeded()
                    })
                })
            })
        })
    }
    
    func hidePanel() {
        closeButton.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.2, animations: {
            self.shopPanelY?.constant = self.shopPanelHeight
            self.layoutIfNeeded()
        })
        
        UIView.animate(withDuration: 0.2, animations: {
            self.pricePanelY?.constant = 0
            self.layoutIfNeeded()
        }, completion: { finished in
            self.isUserInteractionEnabled = false
        })
    }
    
    func animateItemsList(targetId : Int) {
        guard targetId != currentRimId else { return }
        
        UIView.animate(withDuration: 0.1, animations: {
            self.rimsOffset[self.currentRimId].constant = -50
            self.layoutIfNeeded()
        })
        
        UIView.animate(withDuration: 0.1, animations: {
            self.rimsOffset[targetId].constant = -65
            self.layoutIfNeeded()
        }, completion: { finished in
            self.currentRimId = targetId
        })
    }
}
