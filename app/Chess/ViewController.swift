
import UIKit

class ViewController: UIViewController {
    private var game = Game()

    @IBOutlet var boardView: BoardView?
    @IBOutlet var whiteToggle: UISegmentedControl?
    @IBOutlet var blackToggle: UISegmentedControl?
    @IBOutlet weak var SettingsView: UIView!
    @IBOutlet weak var ThemesView: UIView!
    
    private let maxMovesBeforeStalemate = 30
    
    @IBAction func showSettings(_ sender: UIButton) {
        
        SettingsView.isHidden = false
        
    }
    @IBAction func hideSettings(_ sender: UIButton) {
        
        SettingsView.isHidden = true
        
    }
    @IBAction func showThemes(_ sender: UIButton) {
        ThemesView.isHidden = false
    }
    @IBAction func hideThemes(_ sender: UIButton) {
        ThemesView.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        SettingsView.isHidden = true
        ThemesView.isHidden = true
        
        SettingsView.layer.cornerRadius = 20
        ThemesView.layer.cornerRadius = 20
        
        boardView?.delegate = self
        update()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    @IBAction private func togglePlayerType() {
        update()
    }

    @IBAction private func resetGame() {
        game = Game()
        UIView.animate(withDuration: 0.4, animations: {
            self.boardView?.board = self.game.board
        }, completion: { [weak self] _ in
            self?.update()
        })
    }
}

extension ViewController: BoardViewDelegate {
    func boardView(_ boardView: BoardView, didTap position: Position) {
        guard let selection = boardView.selection else {
            if game.canSelectPiece(at: position) {
                setSelection(position)
            }
            return
        }
        guard game.canMove(from: selection, to: position) else {
            if selection == position {
                setSelection(nil)
            } else if game.canSelectPiece(at: position) {
                setSelection(position)
            }
            return
        }
        makeMove(Move(from: selection, to: position))
    }

    private func playerIsHuman(_ color: Color) -> Bool {
        switch color {
        case .white:
            return whiteToggle?.selectedSegmentIndex == 0
        case.black:
            return blackToggle?.selectedSegmentIndex == 0
        }
    }

    private func update() {
        let gameState = game.state
        switch gameState {
        case .checkMate, .staleMate:
            let alert = UIAlertController(
                title: "Game Over",
                message: gameState == .staleMate ?
                    "Stalemate: Nobody wins" :
                    "Checkmate: \(game.turn.other) wins",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Play again", style: .default) { [weak self] _ in
                self?.resetGame()
            })
            self.present(alert, animated: true)
        case .idle, .check:
            if game.moveCounter >= 30 {
                let alert = UIAlertController(
                    title: "Game over",
                    message: "Nobody wins",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Play again", style: .default) { [weak self] _ in
                    self?.resetGame()
                })
                self.present(alert, animated: true)
            }
            else if !playerIsHuman(game.turn) {
                makeMove(game.nextMove(for: game.turn))
            }
        }
    }

    private func setSelection(_ position: Position?) {
        let moves = position.map(game.movesForPiece(at:)) ?? []
        UIView.animate(withDuration: 0.2, animations: {
            self.boardView?.selection = position
            self.boardView?.moves = moves
        })
    }

    private func makeMove(_ move: Move) {
        let position = move.to
        guard let boardView = boardView else {
            return
        }
        let oldGame = game
        game.move(from: move.from, to: position)
        let board1 = game.board
        let wasInCheck = game.kingIsInCheck(for: oldGame.turn)
        let wasPromoted = !wasInCheck && game.canPromotePiece(at: position)
        if wasInCheck {
            game = oldGame
        } else if wasPromoted {
            game.promotePiece(at: position, to: .queen)
        }
        let board2 = game.board
        UIView.animate(withDuration: 0.4, animations: {
            boardView.selection = nil
            boardView.board = board1
            boardView.moves = []
        }, completion: { [weak self] _ in
            guard board2 == self?.game.board else { return }
            if wasInCheck {
                UIView.animate(withDuration: 0.2, animations: {
                    boardView.board = board2
                })
                return
            }
            if wasPromoted {
                UIView.animate(withDuration: 0.4, animations: {
                    boardView.board = board2
                }, completion: { [weak self] _ in
                    guard board2 == self?.game.board else { return }
                    self?.update()
                })
                return
            }
            self?.update()
        })
    }
}
