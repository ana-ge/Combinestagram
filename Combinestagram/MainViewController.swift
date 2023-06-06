import UIKit
import RxSwift
import RxRelay

class MainViewController: UIViewController {

  @IBOutlet weak var imagePreview: UIImageView!
  @IBOutlet weak var buttonClear: UIButton!
  @IBOutlet weak var buttonSave: UIButton!
  @IBOutlet weak var itemAdd: UIBarButtonItem!
  
  private let disposeBag = DisposeBag()
  private let images = BehaviorRelay<[UIImage]>(value: [])

  override func viewDidLoad() {
    super.viewDidLoad()
    images
      .subscribe(onNext: { [weak imagePreview] photos in
        guard let preview = imagePreview else { return }
        preview.image = photos.collage(size: preview.frame.size)
      })
      .disposed(by: disposeBag)
    
    images
      .subscribe(onNext: { [weak self] photos in
      self?.updateUI(photos: photos)
    })
    .disposed(by: disposeBag)
  }
  
  @IBAction func actionClear() {
    images.accept([])

  }

  @IBAction func actionSave() {
    guard let image = imagePreview.image else { return }
    PhotoWriter.save(image)
      .asSingle()
      .subscribe(
        onSuccess: { [weak self] id in
        self?.showMessage("Saved with id: \(id)")
        self?.actionClear()
      },
        onError: { [weak self] error in
          self?.showMessage("Error", description: error.localizedDescription)
        }
    )
      .disposed(by: disposeBag)
  }

  @IBAction func actionAdd() {
//    let newImages = images.value + [UIImage(named: "IMG_1907.jpg")!]
//    images.accept(newImages)
    let photosViewController = storyboard!.instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController
    
    let newPhotos = photosViewController.selectedPhotos
      .share()
    
    newPhotos
      .subscribe(
        onNext: { [weak self] newImage in
          guard let images = self?.images else { return }
          images.accept(images.value + [newImage])
        },
      onDisposed: {
        print("Completed photo selection")
      }
      )
      .disposed(by: disposeBag)
    
    navigationController!.pushViewController(photosViewController, animated: true)
    
    newPhotos
      .ignoreElements()
      .subscribe(onCompleted: { [weak self] in
        self?.updateNavigationIcon()
      })
      .disposed(by: disposeBag)

  }

  func showMessage(_ title: String, description: String? = nil) {
    alert(title: title, text: description)
      .subscribe()
      .disposed(by: disposeBag)
  }
  
  private func updateUI(photos: [UIImage]) {
    buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
    buttonClear.isEnabled = photos.count > 0
    itemAdd.isEnabled = photos.count < 6
    title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
  }
  
  private func updateNavigationIcon() {
    let icon = imagePreview.image?
      .scaled(CGSize(width: 22, height: 22))
      .withRenderingMode(.alwaysOriginal)
    
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      image: icon,
      style: .done,
      target: nil,
      action: nil)
  }
}
