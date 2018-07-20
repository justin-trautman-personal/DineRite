//
//  RestaurantProfileViewController.swift
//  CleanEats
//
//  Created by Joshua Danner on 6/28/18.
//  Copyright © 2018 Justin Trautman. All rights reserved.
//

import UIKit

class RestaurantProfileViewController: UIViewController, UIScrollViewDelegate {
    
    // MARK: - IBOutlets
    
    @IBOutlet var restaurantProfileView: UIView!
    @IBOutlet weak var favoriteStar: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var slideScrollView: UIScrollView!{
        didSet {
            slideScrollView.delegate = self
        }
    }
    @IBOutlet weak var slidePageControl: UIPageControl!
    
    @IBOutlet weak var ratingStar: UIImageView!
    @IBOutlet weak var restaurantNameLabel: UILabel!
    @IBOutlet weak var totalReviewsLabel: UILabel!
    @IBOutlet weak var hoursOfOperationLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var aboutContainerView: UIView!
    @IBOutlet weak var healthRatingContainerView: UIView!
    @IBOutlet weak var reviewContainerView: UIView!
    
    var restaurant: Businesses? 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(scrollView)
        setupNavigationBarItems()
        slideScrollView.delegate = self
        slides = createSlides()
        setupSlideScrollView(slides: slides)
        slidePageControl.numberOfPages = slides.count
        slidePageControl.currentPage = 0
        scrollView.contentSize = CGSize(width: 375, height: 800)
        scoreLabel.layer.masksToBounds = true
        scoreLabel.layer.cornerRadius = 5
        view.bringSubview(toFront: slidePageControl)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        updateView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    
    // Horizontal ScrollView
    var slides: [Slide] = []
    
    func createSlides() -> [Slide] {
        let slide1 : Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        slide1.slideImageView.image = UIImage(named: "Cubbys")
        slide1.contentMode = .scaleAspectFit
        let slide2 : Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        slide2.slideImageView.image = UIImage(named: "pooh2")
        slide2.contentMode = .scaleAspectFit
        let slide3 : Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        slide3.slideImageView.image = UIImage(named: "pooh3")
        slide3.contentMode = .scaleAspectFit
        let slide4 : Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        slide4.slideImageView.image = UIImage(named: "pooh4")
        slide4.contentMode = .scaleAspectFit
        let slide5 : Slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        slide5.slideImageView.image = UIImage(named: "pooh5")
        slide5.contentMode = .scaleAspectFit
        
        return [slide1, slide2, slide3, slide4, slide5]
    }
    
    func setupSlideScrollView(slides : [Slide]) {
        
        slideScrollView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height / 180)
        slideScrollView.contentSize = CGSize(width: view.frame.width * CGFloat(slides.count), height: view.frame.height / 180)
        slideScrollView.isPagingEnabled = true
        
        for i in 0 ..< slides.count {
            slides[i].frame = CGRect(x: view.frame.width * CGFloat(i), y: 0, width: view.frame.width, height: view.frame.height)
            slideScrollView.addSubview(slides[i])
        }
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x/view.frame.width)
        slidePageControl.currentPage = Int(pageIndex)
        
        let maximumHorizontalOffset: CGFloat = scrollView.contentSize.width - scrollView.frame.width
        let currentHorizontalOffset: CGFloat = scrollView.contentOffset.x
        
        // vertical
        let maximumVerticalOffset: CGFloat = scrollView.contentSize.height - scrollView.frame.height
        let currentVerticalOffset: CGFloat = scrollView.contentOffset.y
        
        let _: CGFloat = currentHorizontalOffset / maximumHorizontalOffset
        let _: CGFloat = currentVerticalOffset / maximumVerticalOffset
        
    }
    // Adding Image to Navigation Item
    func setupNavigationBarItems() {
        let logo = UIImage(named: "DineRiteNew")
        var imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        imageView = UIImageView(image: logo)
        imageView.contentMode = .scaleAspectFit
        self.navigationItem.titleView = imageView
        self.navigationItem.hidesBackButton = true
        
    }

    // MARK: - IBActions
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        
        let getIndex = segmentedControl.selectedSegmentIndex
        switch getIndex
        {
        case 0:
            print("First Segment Selected")
            aboutContainerView.isHidden = false
            healthRatingContainerView.isHidden = true
            reviewContainerView.isHidden = true
        case 1:
            print("Second Segment Selected")
            aboutContainerView.isHidden = true
            healthRatingContainerView.isHidden = false
            reviewContainerView.isHidden = true
        case 2:
            print("Third segment selected")
            aboutContainerView.isHidden = true
            healthRatingContainerView.isHidden = true
            reviewContainerView.isHidden = false
            
        default:
            break
        }
    }
    
    @IBAction func favoriteStarButtonTapped(_ sender: UIButton) {
        
        guard let name = restaurantNameLabel.text,
              let healthScore = scoreLabel.text else { return }
        
        print("Star Button Tapped")
        FavoriteController.shared.create(image: "test", name: name, healthScore: healthScore, rating: "5 Stars", phone: "12345", description: "Test")
    
            favoriteStar.setImage(#imageLiteral(resourceName: "FavoriteStarFilled"), for: .normal)
            showFavoriteSavedAlert()
            FavoriteViewController.shared.updateTableView()
        
            favoriteStar.setImage(#imageLiteral(resourceName: "Favicon1"), for: .disabled)
    }
    
    func updateView() {
        guard let
            restaurant = restaurant,
            let name = restaurant.restaurantName, let image = restaurant.imageForRating else { return }
        restaurantNameLabel.text = name
        ratingStar.image = image
    }
    
    func showFavoriteSavedAlert() {
        
        let noResultsAlert = UIAlertController(title: nil, message: "Restaurant successfully added to your favorites!", preferredStyle: .alert)
        noResultsAlert.addAction(UIAlertAction(title: "Sweet!", style: .default, handler: nil))
        self.present(noResultsAlert, animated: true)
    }
}






