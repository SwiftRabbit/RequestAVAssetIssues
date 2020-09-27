//
//  ViewController.swift
//  RequestAVAssetIssues
//
//  Created by leopoldroitel on 9/27/20.
//

import AVFoundation
import UIKit
import Photos
import PhotosUI
import MobileCoreServices
import CoreGraphics

final class ViewController: UIViewController {

  private var player: AVPlayer?
  private var playerLayer: AVPlayerLayer?

  override func viewDidLoad() {
    super.viewDidLoad()
    
    player = AVPlayer()
    player?.allowsExternalPlayback = false
    let playerLayer = AVPlayerLayer(player: self.player)
    self.playerLayer =  playerLayer

    view.layer.addSublayer(playerLayer)
    playerLayer.backgroundColor = UIColor.red.cgColor
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    playerLayer?.frame = view.bounds
  }

  @IBAction private func didTapGallery(_ sender: Any) {
    var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
    configuration.filter = PHPickerFilter.videos
    let videoPickerController = PHPickerViewController(configuration: configuration)
    videoPickerController.delegate = self
    present(videoPickerController, animated: true, completion: nil)
  }
}

extension ViewController: PHPickerViewControllerDelegate {
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true, completion: nil)

    guard results.count > 0 else {
      return
    }
    guard let firstPHAssetIdentifier = results.first?.assetIdentifier else {
      fatalError("No asset identifier")
    }
    let fetchOptions = PHFetchOptions()
    guard let phAsset = PHAsset.fetchAssets(withLocalIdentifiers: [firstPHAssetIdentifier], options: fetchOptions).firstObject else {
      fatalError("No asset identifier")
    }
    guard phAsset.mediaType == .video else {
      fatalError("Asset not of the video type")
    }

    let options = PHVideoRequestOptions()
    options.isNetworkAccessAllowed = true
    options.progressHandler = { progress, _, _, _ in
      print("Progress: \(progress)")
    }

    // Adding this line makes it work
//    options.deliveryMode = .highQualityFormat

    PHCachingImageManager.default().requestAVAsset(forVideo: phAsset, options: options) { [weak self] avAsset, _, info in

      guard info?[PHImageCancelledKey] == nil && info?[PHImageErrorKey] == nil else {
        print("Error or cancelled. Info: \(String(describing: info))")
        return
      }
      guard let avAsset = avAsset else {
        print("Asset is nil. Info: \(String(describing: info))")
        return
      }
      guard let videoTrack = avAsset.tracks(withMediaType: .video).first else {
        print("Cound not extract video track from AvAsset") // <-
        return
      }
      guard (!__CGSizeEqualToSize(videoTrack.naturalSize, CGSize(width: 0, height: 0))) else {
        print("We should never have a track with CGSize 0, this is what happens though")
        return
      }

      let playerItem = AVPlayerItem(asset: avAsset)
      self?.player?.replaceCurrentItem(with: playerItem)
      self?.player?.play()
    }
  }
}

