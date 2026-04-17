import random

class Card:
    def __init__(self, suit, rank, value):
        self.suit = suit
        self.rank = rank
        self.value = value
        # Les couleurs rouges pour l'interface
        self.color = "red" if suit in ['♥', '♦'] else "black"

    def __str__(self):
        return f"{self.rank}{self.suit}"

class Deck:
    def __init__(self):
        self.cards = []
        self.build()

    def build(self):
        suits = ['♥', '♦', '♣', '♠']
        # Valeurs par défaut (adaptables selon le jeu)
        ranks = [('2', 2), ('3', 3), ('4', 4), ('5', 5), ('6', 6), ('7', 7), 
                 ('8', 8), ('9', 9), ('10', 10), ('V', 10), ('D', 10), ('R', 10), ('A', 11)]
        self.cards = [Card(s, r, v) for s in suits for r, v in ranks]
        random.shuffle(self.cards)

    def draw(self):
        return self.cards.pop() if self.cards else None