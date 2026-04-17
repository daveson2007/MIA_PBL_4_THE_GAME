import flet as ft
import random
import time
from utils.deck import Deck
from utils.component import create_ui_card

# Valeurs des cartes à la Belote (Ordre et Points)
# (Points Non-Atout, Points Atout)
BELOTE_VALUES = {
    'Valet': (2, 20),
    '9': (0, 14),
    'As': (11, 11),
    '10': (10, 10),
    'Roi': (4, 4),
    'Reine': (3, 3),
    '8': (0, 0),
    '7': (0, 0)
}

def get_game_view():
   # 1. Préparation du jeu
    full_deck = Deck()
    belote_ranks = ['7', '8', '9', '10', 'Valet', 'Reine', 'Roi', 'As']
    
    # On filtre les cartes existantes
    deck_32 = [c for c in full_deck.cards if str(c.rank) in belote_ranks]

    # SI l'erreur persiste ou si le deck est vide, on le reconstruit manuellement
    # en respectant l'argument 'value' demandé par ta classe Card
    if len(deck_32) < 32:
        from utils.deck import Card
        suits = ["Trefle", "Coeur", "Carreau", "Pique"]
        deck_32 = []
        for s in suits:
            for r in belote_ranks:
                # Ici, on ajoute le 3ème argument 'value' (on met 0 par défaut)
                # car ta classe Card l'exige : Card(suit, rank, value)
                deck_32.append(Card(s, r, 0)) 
    
    random.shuffle(deck_32)

    # 2. Distribution (8 cartes par joueur)
   # Distribue seulement si le deck a assez de cartes
    player_hand = [deck_32.pop() for _ in range(8)] if len(deck_32) >= 8 else []
    ai_hands = [[deck_32.pop() for _ in range(8)] for _ in range(3)] if len(deck_32) >= 24 else [[],[],[]]
    
    # Définition de l'Atout au hasard pour cette partie
    atout_suit = random.choice(["Trefle", "Coeur", "Carreau", "Pique"])
    
    # État du jeu sur la table
    current_trick = [] # Le pli en cours (les cartes posées)
    player_score = 0
    ai_score = 0 # Score global des IA

    # Composants UI
    status_text = ft.Text("À vous de jouer la première carte !", size=18, color=ft.Colors.AMBER)
    atout_text = ft.Text(f"Atout : {atout_suit}", size=20, weight="bold", color=ft.Colors.RED_400)
    score_text = ft.Text(f"Score - Vous: 0 | IA: 0", size=16)
    
    trick_row = ft.Row(alignment=ft.MainAxisAlignment.CENTER, spacing=10)
    hand_row = ft.Row(wrap=True, alignment=ft.MainAxisAlignment.CENTER, spacing=5)

    def evaluate_trick():
        """Détermine qui a gagné le pli (simplifié)"""
        if not current_trick: return 0
        
        asked_suit = current_trick[0].suit
        best_card = current_trick[0]
        best_index = 0
        points = 0
        
        for i, card in enumerate(current_trick):
            # Calcul des points du pli
            is_atout = (card.suit == atout_suit)
            points += BELOTE_VALUES[card.rank][1 if is_atout else 0]
            
            # Qui gagne ?
            best_is_atout = (best_card.suit == atout_suit)
            
            if is_atout and not best_is_atout:
                best_card = card
                best_index = i
            elif is_atout and best_is_atout:
                if BELOTE_VALUES[card.rank][1] > BELOTE_VALUES[best_card.rank][1]:
                    best_card = card
                    best_index = i
            elif card.suit == asked_suit and not best_is_atout:
                if BELOTE_VALUES[card.rank][0] > BELOTE_VALUES[best_card.rank][0]:
                    best_card = card
                    best_index = i
                    
        return best_index, points

    def ai_turn(page):
        """Fait jouer les 3 IA à la suite"""
        nonlocal current_trick, ai_score, player_score
        
        for i, hand in enumerate(ai_hands):
            if hand:
                # L'IA joue au hasard pour l'instant (on prend sa première carte)
                card_played = hand.pop(0)
                current_trick.append(card_played)
                status_text.value = f"L'IA {i+1} a joué."
                update_ui()
                page.update()
                time.sleep(0.5) # Petite pause visuelle
        
        # Le pli est terminé (4 cartes)
        winner_idx, points = evaluate_trick()
        if winner_idx == 0:
            player_score += points
            status_text.value = f"Vous remportez le pli ! (+{points} pts)"
        else:
            ai_score += points
            status_text.value = f"L'IA {winner_idx} remporte le pli. (+{points} pts)"
        
        score_text.value = f"Score - Vous: {player_score} | IA: {ai_score}"
        update_ui()
        page.update()
        
        # Nettoyer la table après 2 secondes
        time.sleep(2)
        current_trick.clear()
        
        if not player_hand:
            status_text.value = "Partie terminée !"
        else:
            status_text.value = "Nouveau pli, à vous !"
            
        update_ui()
        page.update()

    def play_card(idx, e):
        """Action quand tu cliques sur une de tes cartes"""
        if len(current_trick) == 0 or len(current_trick) == 4:
            current_trick.clear() # On s'assure que la table est vide
            
            # Le joueur pose sa carte
            played = player_hand.pop(idx)
            current_trick.append(played)
            status_text.value = "Au tour des IA..."
            update_ui()
            e.page.update()
            
            # On lance le tour des IA
            ai_turn(e.page)
        else:
            status_text.value = "Attendez la fin du pli !"
            e.page.update()

    def update_ui():
        # Mise à jour des cartes sur la table
        trick_row.controls = [create_ui_card(c) for c in current_trick]
        
        # Mise à jour de ta main
        hand_row.controls.clear()
        for i, card in enumerate(player_hand):
            hand_row.controls.append(
                ft.GestureDetector(
                    content=create_ui_card(card),
                    on_tap=lambda e, idx=i: play_card(idx, e)
                )
            )

    update_ui()

    return ft.Column([
        ft.Text("Belote", size=32, weight="bold", color=ft.Colors.CYAN),
        ft.Row([atout_text, score_text], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
        status_text,
        ft.Divider(),
        
        ft.Text("Le Pli en cours :", italic=True),
        ft.Container(
            content=trick_row, 
            height=150, 
            bgcolor=ft.Colors.BLUE_GREY_900, 
            border_radius=10, 
            padding=10
        ),
        
        ft.Divider(),
        ft.Text("Votre main (Cliquez pour jouer) :", weight="bold"),
        hand_row,
        
    ], expand=True, horizontal_alignment=ft.CrossAxisAlignment.CENTER)