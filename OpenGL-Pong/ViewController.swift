//
//  Copyright © Borna Noureddin. All rights reserved.
//

import GLKit

extension ViewController: GLKViewControllerDelegate {
    func glkViewControllerUpdate(_ controller: GLKViewController) {
        glesRenderer.update()
    }
}

class ViewController: GLKViewController, UIGestureRecognizerDelegate {
    
    private var context: EAGLContext?
    private var glesRenderer: Renderer!
    private var dragStart: CGPoint!
    
    private func setupGL() {
        context = EAGLContext(api: .openGLES3)
        EAGLContext.setCurrent(context)
        if let view = self.view as? GLKView, let context = context {
            view.context = context
            delegate = self as GLKViewControllerDelegate
            glesRenderer = Renderer()
            glesRenderer.setup(view)
            glesRenderer.loadModels()
            
            let movePaddles = UIPanGestureRecognizer(target: self, action: #selector(movePaddles))
            movePaddles.minimumNumberOfTouches = 1
            movePaddles.maximumNumberOfTouches = 1
            movePaddles.delegate = self as UIGestureRecognizerDelegate
            self.view.addGestureRecognizer(movePaddles)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGL()
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(self.doSingleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        view.addGestureRecognizer(singleTap)
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glesRenderer.draw(rect)
    }
    
    @objc func doSingleTap(_ sender: UITapGestureRecognizer) {
        glesRenderer.box2d.launchBall()
    }
    
    @objc func movePaddles(recognizer:UIPanGestureRecognizer)
    {
        if (recognizer.state != UIGestureRecognizer.State.ended) {
            if (recognizer.state == UIGestureRecognizer.State.began) {
                dragStart = recognizer.location(in: self.view)
            } else {
                let newPt = recognizer.location(in: self.view)
                let touchDist = recognizer.translation(in: view)
                
                if (newPt.y > 425) {
                    //print (touchDist);
                    if (glesRenderer.box2d.paddle2_POS_X < 675
                        && glesRenderer.box2d.paddle2_POS_X > 125) {
                        glesRenderer.box2d.paddle2_POS_X =
                        glesRenderer.box2d.paddle2_POS_X + Float(touchDist.x / 3);
                    }
                    if (glesRenderer.box2d.paddle2_POS_X > 675) {
                        glesRenderer.box2d.paddle2_POS_X =
                        glesRenderer.box2d.paddle2_POS_X - abs(Float(touchDist.x / 3));
                    }
                    if (glesRenderer.box2d.paddle2_POS_X < 125) {
                        glesRenderer.box2d.paddle2_POS_X =
                        glesRenderer.box2d.paddle2_POS_X + abs(Float(touchDist.x / 3))
                    }
                    
                }
                if (newPt.y < 425) {
                    //print (touchDist);
                    if (glesRenderer.box2d.paddle1_POS_X < 675
                        && glesRenderer.box2d.paddle1_POS_X > 125) {
                        glesRenderer.box2d.paddle1_POS_X =
                        glesRenderer.box2d.paddle1_POS_X + Float(touchDist.x / 3);
                    }
                    if (glesRenderer.box2d.paddle1_POS_X > 675) {
                        glesRenderer.box2d.paddle1_POS_X =
                        glesRenderer.box2d.paddle1_POS_X - abs(Float(touchDist.x / 3));
                    }
                    if (glesRenderer.box2d.paddle1_POS_X < 125) {
                        glesRenderer.box2d.paddle1_POS_X =
                        glesRenderer.box2d.paddle1_POS_X + abs(Float(touchDist.x / 3))
                    }
                    
                }
            }
        }
    }

}
