//
//  EpisodeDetailViewController.swift
//  Podcast
//
//  Created by Mark Bryan on 4/11/17.
//  Copyright © 2017 Cornell App Development. All rights reserved.
//

import UIKit

class EpisodeDetailViewController: ViewController, EpisodeDetailHeaderViewDelegate {

    var episode: Episode?
    var scrollView: UIScrollView = UIScrollView()
    var headerView: EpisodeDetailHeaderView = EpisodeDetailHeaderView()
    var episodeDescriptionView: UITextView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(scrollView)
        mainScrollView = scrollView
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollView.addSubview(headerView)
        headerView.delegate = self
        
        episodeDescriptionView.isEditable = false
        episodeDescriptionView.font = ._14RegularFont()
        episodeDescriptionView.textColor = .charcoalGrey
        episodeDescriptionView.showsVerticalScrollIndicator = false
        episodeDescriptionView.backgroundColor = .clear
        scrollView.addSubview(episodeDescriptionView)
        
        if let episode = episode {
            headerView.setupForEpisode(episode: episode)
            episodeDescriptionView.attributedText = episode.attributedDescriptionString()
        }
        
        headerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        episodeDescriptionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.equalToSuperview()
        }
    }
    
    // EpisodeDetailHeaderViewCellDelegate methods
    
    func episodeDetailHeaderDidPressRecommendButton(view: EpisodeDetailHeaderView) {
        guard let headerEpisode = episode else { return }
        headerEpisode.recommendedChange(completion: view.setRecommendedButtonToState)
    }
    
    func episodeDetailHeaderDidPressMoreButton(view: EpisodeDetailHeaderView) {
        guard let episode = episode else { return }
        let option1 = ActionSheetOption(type: .download(selected: episode.isDownloaded), action: nil)
        var header: ActionSheetHeader?
        
        if let image = view.episodeArtworkImageView.image, let title = view.episodeTitleLabel.text, let description = view.dateLabel.text {
            header = ActionSheetHeader(image: image, title: title, description: description)
        }
        
        let actionSheetViewController = ActionSheetViewController(options: [option1], header: header)
        showActionSheetViewController(actionSheetViewController: actionSheetViewController)
    }
    
    func episodeDetailHeaderDidPressPlayButton(view: EpisodeDetailHeaderView) {
        guard let episode = episode, let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        view.setPlayButtonToState(isPlaying: true)
        appDelegate.showPlayer(animated: true)
        Player.sharedInstance.playEpisode(episode: episode)
    }
    
    func episodeDetailHeaderDidPressBookmarkButton(view: EpisodeDetailHeaderView) {
        guard let episode = episode else { return }
        let completion = view.setBookmarkButtonToState
        episode.bookmarkChange(completion: completion)
    }
    
    func episodeDetailHeaderDidPressSeriesTitleLabel(view: EpisodeDetailHeaderView) {
        guard let episode = episode else { return }
        let seriesDetailViewController = SeriesDetailViewController()
        seriesDetailViewController.fetchSeries(seriesID: episode.seriesID)
        navigationController?.pushViewController(seriesDetailViewController, animated: true)
    }
    
}
