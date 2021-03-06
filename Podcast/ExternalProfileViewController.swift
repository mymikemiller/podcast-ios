//
//  ProfileViewController.swift
//  Podcast
//
//  Created by Drew Dunne on 10/12/16.
//  Copyright © 2016 Cornell App Development. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class ExternalProfileViewController: ViewController, UITableViewDataSource, UITableViewDelegate, ProfileHeaderViewDelegate, RecommendedSeriesTableViewCellDelegate, RecommendedSeriesTableViewCellDataSource, RecommendedEpisodesOuterTableViewCellDelegate, RecommendedEpisodesOuterTableViewCellDataSource, EpisodeDownloader {
    
    var profileHeaderView: ProfileHeaderView!
    var miniHeader: ProfileMiniHeader!
    var profileTableView: UITableView!
    var backButton: UIButton!
    
    var loadingAnimation: NVActivityIndicatorView!
    
    let headerViewHeight = ProfileHeaderView.height
    let miniBarHeight = ProfileHeaderView.miniBarHeight
    let sectionHeaderHeight: CGFloat = 37

    let padding: CGFloat = 12.5
    let backButtonHeight: CGFloat = 21
    let backButtonWidth: CGFloat = 56
    let iPhoneXOffset: CGFloat = 24

    var scrollYOffset: CGFloat = 109
    
    let FooterHeight: CGFloat = 0
    var sectionNames = ["Subscriptions", "recasted"]
    let sectionHeaderHeights: [CGFloat] = [52, 52]
    let sectionContentClasses: [AnyClass] = [RecommendedSeriesTableViewCell.self, RecommendedEpisodesOuterTableViewCell.self]
    let sectionContentIndentifiers = ["SeriesCell", "EpisodesCell"]
    var user: User?
    var favorites: [Episode]?
    var subscriptions: [Series]?
    
    convenience init(user: User) {
        self.init()
        self.user = user
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .paleGrey
        
        if System.isiPhoneX() { scrollYOffset -= iPhoneXOffset }
        
        let profileHeaderEmptyFrame = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: ProfileHeaderView.profileAreaHeight))
        profileHeaderEmptyFrame.backgroundColor = .sea
        view.addSubview(profileHeaderEmptyFrame)
        
        profileTableView = UITableView(frame: .zero, style: .grouped)
        for (contentClass, identifier) in zip(sectionContentClasses, sectionContentIndentifiers) {
            profileTableView.register(contentClass.self, forCellReuseIdentifier: identifier)
        }
        profileTableView.delegate = self
        profileTableView.dataSource = self
        profileTableView.backgroundColor = .paleGrey
        profileTableView.rowHeight = UITableViewAutomaticDimension
        profileTableView.separatorStyle = .none
        profileTableView.showsVerticalScrollIndicator = false
        mainScrollView = profileTableView
        view.addSubview(profileTableView)
        profileTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let backgroundExtender = UIView(frame: CGRect(x: 0, y: 0-view.frame.height+20, width: view.frame.width, height: view.frame.height))
        backgroundExtender.backgroundColor = .sea
        profileTableView.addSubview(backgroundExtender)
        profileTableView.sendSubview(toBack: backgroundExtender)
        
        // Instantiate tableViewHeader and the minified header
        profileHeaderView = ProfileHeaderView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: headerViewHeight))
        profileTableView.tableHeaderView = profileHeaderView
        profileHeaderView.delegate = self
        
        miniHeader = ProfileMiniHeader(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: miniBarHeight))
        view.addSubview(miniHeader)
        
        backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "backArrowLeft"), for: .normal)
        backButton.contentHorizontalAlignment = .left
        backButton.adjustsImageWhenHighlighted = true
        backButton.addTarget(self, action: #selector(didPressBackButton), for: .touchUpInside)
        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(padding)
            make.top.equalToSuperview().inset(UIApplication.shared.statusBarFrame.height + (miniBarHeight - UIApplication.shared.statusBarFrame.height - backButtonHeight) / 2)
            make.width.equalTo(backButtonWidth)
            make.height.equalTo(backButtonHeight)
        }
        
        loadingAnimation = LoadingAnimatorUtilities.createLoadingAnimator()
        loadingAnimation.center = view.center
        view.addSubview(loadingAnimation)
        loadingAnimation.startAnimating()
        UIApplication.shared.statusBarStyle = .lightContent
        view.bringSubview(toFront: backButton)
        
        if let user = user {
            setUser(user: user)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        UIApplication.shared.statusBarStyle = .lightContent
        if let user = user {
            updateViewWithUser(user)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        navigationController?.setNavigationBarHidden(false, animated: true)
        UIApplication.shared.statusBarStyle = .default
    }
    
    func fetchUser(id: String) {
        
        let userRequest = FetchUserByIDEndpointRequest(userID: id)
        userRequest.success = { (endpointRequest: EndpointRequest) in
            if let results = endpointRequest.processedResponseValue as? User {
                self.user = results
                self.updateViewWithUser(results)
                self.loadingAnimation.stopAnimating()
                UIApplication.shared.statusBarStyle = .lightContent
            }
        }
        userRequest.failure = { (endpointRequest: EndpointRequest) in
            // Display error
            print("Could not load user, request failed")
            self.loadingAnimation.stopAnimating()
        }
        System.endpointRequestQueue.addOperation(userRequest)
        
        // Now request user subscriptions and favorites
        let favoritesRequest = FetchUserRecommendationsEndpointRequest(userID: id)
        favoritesRequest.success = { (favoritesEndpointRequest: EndpointRequest) in
            guard let results = favoritesEndpointRequest.processedResponseValue as? [Episode] else { return }
            self.favorites = results
            self.profileTableView.reloadData()
        }
        favoritesRequest.failure = { (endpointRequest: EndpointRequest) in
            // Display error
            print("Could not load user favorites, request failed")
            self.loadingAnimation.stopAnimating()
        }
        System.endpointRequestQueue.addOperation(favoritesRequest) // UNCOMMENT WHEN FAVORITES ARE DONE
        
        let subscriptionsRequest = FetchUserSubscriptionsEndpointRequest(userID: id)
        subscriptionsRequest.success = { (subscriptionsEndpointRequest: EndpointRequest) in
            guard let results = subscriptionsEndpointRequest.processedResponseValue as? [Series] else { return }
            self.subscriptions = results
            self.profileTableView.reloadData()
        }
        subscriptionsRequest.failure = { (endpointRequest: EndpointRequest) in
            // Display error
            print("Could not load user subscriptions, request failed")
            self.loadingAnimation.stopAnimating()
        }
        System.endpointRequestQueue.addOperation(subscriptionsRequest)
    }
    
    private func setUser(user: User) {
        self.user = user
        self.updateViewWithUser(user)
        self.loadingAnimation.stopAnimating()
        UIApplication.shared.statusBarStyle = .lightContent
        
        // Now request user subscriptions and favorites
        let favoritesRequest = FetchUserRecommendationsEndpointRequest(userID: user.id)
        favoritesRequest.success = { (favoritesEndpointRequest: EndpointRequest) in
            guard let results = favoritesEndpointRequest.processedResponseValue as? [Episode] else { return }
            self.favorites = results
            
            // Need guard in case view hasn't been created
            guard let profileTableView = self.profileTableView else { return }
            profileTableView.reloadData()
        }
        favoritesRequest.failure = { (endpointRequest: EndpointRequest) in
            print("Could not load user favorites, request failed")
            self.loadingAnimation.stopAnimating()
        }
        System.endpointRequestQueue.addOperation(favoritesRequest)
        
        let subscriptionsRequest = FetchUserSubscriptionsEndpointRequest(userID: user.id)
        subscriptionsRequest.success = { (subscriptionsEndpointRequest: EndpointRequest) in
            guard let results = subscriptionsEndpointRequest.processedResponseValue as? [Series] else { return }
            self.subscriptions = results
            
            // Need guard in case view hasn't been created
            guard let profileTableView = self.profileTableView else { return }
            profileTableView.reloadData()
        }
        subscriptionsRequest.failure = { (endpointRequest: EndpointRequest) in
            print("Could not load user subscriptions, request failed")
            self.loadingAnimation.stopAnimating()
        }
        System.endpointRequestQueue.addOperation(subscriptionsRequest)
    }
    
    func updateViewWithUser(_ user: User) {
        self.user = user
        if let currentUser = System.currentUser, currentUser == user {
            sectionNames[1] = "You've recasted"
        } else {
            sectionNames[1] = "\(user.firstName) recasted"
        }
        // Update views
        profileHeaderView.setUser(user)
        miniHeader.setUser(user)
        profileTableView.reloadData()
    }
    
    @objc func didPressBackButton() {
        let _ = navigationController?.popViewController(animated: true)
    }
    
    // Mark: - ProfileHeaderView
    func profileHeaderDidPressFollowButton(profileHeader: ProfileHeaderView) {
        profileHeader.followButton.isEnabled = false // Disable so user cannot send multiple requests
        profileHeader.followButton.setTitleColor(.offBlack, for: .disabled)
        let completion: ((Bool, Int) -> ()) = { (isFollowing, _) in
            profileHeader.followButton.isEnabled = true
            profileHeader.followButton.isSelected = isFollowing
            
        }
        // Safe because this function isn't called unless the view has been set!
        user!.followChange(completion: completion)
    }
    
    func profileHeaderDidPressFollowers(profileHeader: ProfileHeaderView) {
        let followersViewController = FollowerFollowingViewController(user: user!)
        followersViewController.followersOrFollowings = .Followers
        navigationController?.pushViewController(followersViewController, animated: true)
    }
    
    func profileHeaderDidPressFollowing(profileHeader: ProfileHeaderView) {
        let followingViewController = FollowerFollowingViewController(user: user!)
        followingViewController.followersOrFollowings = .Followings
        navigationController?.pushViewController(followingViewController, animated: true)
    }
    
    // MARK: - TableView DataSource & Delegate
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // don't know how to condense this using an array like the other functions
        guard let cell = tableView.dequeueReusableCell(withIdentifier: sectionContentIndentifiers[indexPath.section]) else { return UITableViewCell() }
        if let cell = cell as? RecommendedSeriesTableViewCell {
            cell.dataSource = self
            cell.delegate = self
            cell.backgroundColor = .paleGrey
            cell.reloadCollectionViewData()
        } else if let cell = cell as? RecommendedEpisodesOuterTableViewCell {
            cell.dataSource = self
            cell.delegate = self
            cell.tableView.reloadData()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sectionHeaderHeights[section]
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = ProfileSectionHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: sectionHeaderHeights[section]))
        header.setSectionText(sectionName: sectionNames[section])
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            guard let numSubs = numberOfRecommendedSeries() else { return RecommendedSeriesTableViewCell.recommendedSeriesTableViewCellHeight }
            if numSubs > 0 {
                return RecommendedSeriesTableViewCell.recommendedSeriesTableViewCellHeight
            }
            if System.currentUser == user {
                return NullProfileCollectionViewCell.heightForCurrentUser
            }
            return NullProfileCollectionViewCell.heightForUser
            
        case 1:
            guard let numFavs = numberOfRecommendedEpisodes() else { return EpisodeSubjectView.episodeSubjectViewHeight }
            if numFavs > 0 {
                return CGFloat(numFavs) * EpisodeSubjectView.episodeSubjectViewHeight
            }
            return EpisodeSubjectView.episodeSubjectViewHeight
            
        default:
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionNames.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //TODO: might need to fix this later but was quick fix because this was throwing a nil exception
        guard let profileHeader = profileHeaderView, let miniHeaderView = miniHeader else { return }
        profileHeader.animateByYOffset(scrollView.contentOffset.y)
        let yOffset = scrollView.contentOffset.y
        let aboveThreshold = (yOffset > scrollYOffset)
        miniHeaderView.setMiniHeaderState(aboveThreshold)
        let showsShadow = (yOffset > ProfileHeaderView.profileAreaHeight - ProfileHeaderView.miniBarHeight)
        miniHeaderView.setMiniHeaderShadowState(showsShadow)
    }
    
    // MARK: - RecommendedSeriesTableViewCell DataSource & Delegate
    
    func recommendedSeriesTableViewCell(dataForItemAt indexPath: IndexPath) -> Series? {
        if let subs = subscriptions {
            return subs[indexPath.row]
        }
        return nil
    }
    
    func numberOfRecommendedSeries() -> Int? {
        if let subs = subscriptions {
            return subs.count
        }
        return nil
    }
    
    func getUser() -> User? {
        return user
    }
    
    func recommendedSeriesTableViewCell(cell: UICollectionViewCell, didSelectItemAt indexPath: IndexPath) {
        if let _ = cell as? SeriesGridCollectionViewCell, let subs = subscriptions {
            let seriesDetailViewController = SeriesDetailViewController(series: subs[indexPath.row])
            navigationController?.pushViewController(seriesDetailViewController, animated: true)
        }
        else if let _ = cell as? NullProfileCollectionViewCell {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let tabBarController = appDelegate.tabBarController else { return }
            tabBarController.programmaticallyPressTabBarButton(atIndex: System.discoverTab)
        }
    }
    
    func didReceiveDownloadUpdateFor(episode: Episode) {
        if let row = favorites?.index(of: episode), let cell: RecommendedEpisodesOuterTableViewCell = tableView(profileTableView, cellForRowAt: IndexPath(row: 0, section: 1)) as? RecommendedEpisodesOuterTableViewCell {
            cell.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
        }
    }
    
    // MARK: - RecommendedEpisodesOuterTableViewCell DataSource & Delegate
    
    func recommendedEpisodesTableViewCell(dataForItemAt indexPath: IndexPath) -> Episode? {
        if let favs = favorites {
            return favs[indexPath.row]
        }
        return nil
    }
    
    func numberOfRecommendedEpisodes() -> Int? {
        if let favs = favorites {
            return favs.count
        }
        return nil
    }
    
    func recommendedEpisodesOuterTableViewCell(cell: UITableViewCell, didSelectItemAt indexPath: IndexPath) {
        if let _ = cell as? EpisodeTableViewCell, let favs = favorites {
            let episode = favs[indexPath.row]
            let episodeDetailViewController = EpisodeDetailViewController()
            episodeDetailViewController.episode = episode
            navigationController?.pushViewController(episodeDetailViewController, animated: true)
        }
        else if let _ = cell as? NullProfileTableViewCell{
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let tabBarController = appDelegate.tabBarController else { return }
            tabBarController.programmaticallyPressTabBarButton(atIndex: System.discoverTab)
        }
    }
    
    func recommendedEpisodeOuterTableViewCellDidPressPlayButton(episodeTableViewCell: EpisodeTableViewCell, episode: Episode) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.showPlayer(animated: true)
        Player.sharedInstance.playEpisode(episode: episode)
        episodeTableViewCell.setupWithEpisode(episode: episode)
    }
    
    func recommendedEpisodeOuterTableViewCellDidPressBookmarkButton(episodeTableViewCell: EpisodeTableViewCell, episode: Episode) {
        episode.bookmarkChange(completion: episodeTableViewCell.setBookmarkButtonToState)
    }
    
    func recommendedEpisodeOuterTableViewCellDidPressRecommendButton(episodeTableViewCell: EpisodeTableViewCell, episode: Episode) {
        episode.recommendedChange(completion: episodeTableViewCell.setRecommendedButtonToState)
    }
    
    func recommendedEpisodesOuterTableViewCellDidPressShowActionSheet(episodeTableViewCell: EpisodeTableViewCell, episode: Episode) {
        
        let option1 = ActionSheetOption(type: .download(selected: episode.isDownloaded), action: {
            DownloadManager.shared.downloadOrRemove(episode: episode, callback: self.didReceiveDownloadUpdateFor)
        })
        let shareEpisodeOption = ActionSheetOption(type: .shareEpisode, action: {
            guard let user = System.currentUser else { return }
            let viewController = ShareEpisodeViewController(user: user, episode: episode)
            self.navigationController?.pushViewController(viewController, animated: true)
        })
        
        var header: ActionSheetHeader?
        
        if let image = episodeTableViewCell.episodeSubjectView.podcastImage.image, let title = episodeTableViewCell.episodeSubjectView.episodeNameLabel.text, let description = episodeTableViewCell.episodeSubjectView.dateTimeLabel.text {
            header = ActionSheetHeader(image: image, title: title, description: description)
        }
        
        let actionSheetViewController = ActionSheetViewController(options: [option1, shareEpisodeOption], header: header)
        showActionSheetViewController(actionSheetViewController: actionSheetViewController)
    }

}
