extends Node

# CardManager class to handle card draw, discard, and pile management
class CardManager:
    var draw_pile = []
    var discard_pile = []
    var hand = []

    # Draw a card from the draw pile
    func draw_card():
        if draw_pile.size() > 0:
            var card = draw_pile.pop_back()
            hand.append(card)
            return card
        else:
            return null  # No cards left to draw

    # Discard a card from the hand
    func discard_card(card):
        if card in hand:
            hand.erase(card)
            discard_pile.append(card)

    # Shuffle the discard pile back into the draw pile
    func shuffle_discard():
        draw_pile += discard_pile
        discard_pile.clear()
        draw_pile.shuffle()