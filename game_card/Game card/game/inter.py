import flet as ft
from utils.deck import Deck
from utils.component import create_ui_card

def get_game_view():
    deck = Deck()
    
    # Distribution initiale
    player_hand = [deck.draw() for _ in range(4)]
    ai_hand = [deck.draw() for _ in range(4)]
    opponent_card_count = len(ai_hand)
    
    discard_pile = [deck.draw()]
    selected_indices = []
    has_knocked = False 
    active_suit = discard_pile[-1].suit 

    # --- Éléments d'interface ---
    table_row = ft.Row(wrap=True, spacing=20, alignment=ft.MainAxisAlignment.CENTER)
    hand_row = ft.Row(wrap=True, spacing=10, alignment=ft.MainAxisAlignment.CENTER)
    info_text = ft.Text("À vous de jouer !", size=18, weight="bold", color=ft.Colors.BLUE_400)
    opponent_text = ft.Text(f"Cartes de l'adversaire : {opponent_card_count}", size=16, color=ft.Colors.RED_400)

    def update_ui():
        nonlocal active_suit, opponent_card_count
        # Table
        table_row.controls.clear()
        top_card = discard_pile[-1]
        table_row.controls.append(create_ui_card(top_card))
        if active_suit != top_card.suit:
            table_row.controls.append(ft.Text(f"Couleur demandée : {active_suit}", weight="bold", color="amber"))

        # Main Joueur
        hand_row.controls.clear()
        for i, card in enumerate(player_hand):
            card_ui = create_ui_card(card)
            if i in selected_indices:
                card_ui.border = ft.border.all(3, ft.Colors.BLUE)
                card_ui.margin = ft.margin.only(bottom=20)
            
            hand_row.controls.append(ft.GestureDetector(
                content=card_ui,
                on_tap=lambda _, idx=i: toggle_selection(idx)
            ))
        
        opponent_card_count = len(ai_hand)
        opponent_text.value = f"Cartes de l'adversaire : {opponent_card_count}"

    def apply_penalty(target_hand, nb_cards):
        """Fait piocher des cartes à une main cible"""
        for _ in range(nb_cards):
            if len(deck.cards) > 0:
                target_hand.append(deck.draw())

    def ai_turn():
        nonlocal ai_hand, discard_pile, active_suit
        if not ai_hand: return

        top_card = discard_pile[-1]
        playable_idx = None
        for i, card in enumerate(ai_hand):
            if card.rank == '8' or card.rank == top_card.rank or card.suit == active_suit:
                playable_idx = i
                break
        
        if playable_idx is not None:
            card_played = ai_hand.pop(playable_idx)
            discard_pile.append(card_played)
            active_suit = card_played.suit
            info_text.value = f"L'IA a joué {card_played.rank} de {card_played.suit}"
            
            # Pouvoirs de l'IA contre le joueur
            if card_played.rank == '2': apply_penalty(player_hand, 2)
            elif card_played.rank == '10': apply_penalty(player_hand, 4)
            elif card_played.rank == 'A': 
                info_text.value = "L'IA rejoue (AS) !"
                ai_turn()
        else:
            if len(deck.cards) > 0:
                ai_hand.append(deck.draw())
                info_text.value = "L'IA a pioché."
        
        if not ai_hand:
            info_text.value = "DÉFAITE... L'IA a gagné !"
            info_text.color = ft.Colors.RED_700
            play_button.disabled = True

        update_ui()

    def player_turn(cards_to_play):
        nonlocal player_hand, discard_pile, active_suit, has_knocked, selected_indices
        
        # 1. Pose des cartes
        for i in sorted(selected_indices, reverse=True):
            player_hand.pop(i)
        
        last_card = cards_to_play[-1]
        discard_pile.append(last_card)
        active_suit = last_card.suit
        selected_indices.clear()
        
        # 2. Victoire ?
        if not player_hand:
            info_text.value = "VICTOIRE ! Vous avez vidé votre main !"
            info_text.color = ft.Colors.GREEN_A700
            play_button.disabled = True
            update_ui()
            return

        # 3. Pouvoirs Spéciaux
        rank = last_card.rank
        if rank == '2': apply_penalty(ai_hand, 2 * len(cards_to_play))
        elif rank == '10': apply_penalty(ai_hand, 4 * len(cards_to_play))
        
        info_text.value = "Cartes posées."
        has_knocked = False
        update_ui()
        
        # 4. Tour suivant (si pas d'As)
        if rank != 'A':
            ai_turn()
        else:
            info_text.value = "AS ! Rejouez !"

    def toggle_selection(index):
        if index in selected_indices:
            selected_indices.remove(index)
        else:
            selected_indices.append(index)
        update_ui()
        if play_button.page: play_button.page.update()

    def play_selected_cards(e):
        if not selected_indices: return
        
        cards_to_play = [player_hand[i] for i in sorted(selected_indices)]
        top_card = discard_pile[-1]
        
        # Validation
        first = cards_to_play[0]
        if not all(c.rank == first.rank for c in cards_to_play):
            info_text.value = "Sélectionnez des cartes de même valeur !"
            e.control.page.update()
            return
            
        is_valid = (first.rank == '8') or (first.rank == top_card.rank) or (first.suit == active_suit)
        if not is_valid:
            info_text.value = "Coup invalide !"
            e.control.page.update()
            return

        # Vérification Toc Toc Toc
        if len(player_hand) - len(cards_to_play) == 0 and not has_knocked and len(player_hand) > 1:
            info_text.value = "Oubli du TOC TOC TOC ! +2 cartes."
            apply_penalty(player_hand, 2)
            selected_indices.clear()
            update_ui()
            e.control.page.update()
            return

        player_turn(cards_to_play)
        if e.control.page: e.control.page.update()

    def draw_card(e):
        if len(deck.cards) > 0:
            player_hand.append(deck.draw())
            info_text.value = "Vous piochez. Tour de l'IA."
            update_ui()
            ai_turn()
            if e.control.page: e.control.page.update()

    def knock(e):
        nonlocal has_knocked
        if len(player_hand) <= 2:
            has_knocked = True
            info_text.value = "✊ TOC TOC TOC !"
        e.control.page.update()

    # Définition des boutons (après les fonctions pour éviter UnboundLocalError)
    play_button = ft.ElevatedButton("Jouer", on_click=play_selected_cards)
    draw_button = ft.ElevatedButton("Piocher", on_click=draw_card)
    knock_button = ft.ElevatedButton("✊ Toc Toc", on_click=knock, color="orange")

    update_ui()

    return ft.Column([
        ft.Text("L'Inter (Le Jeu de la Terre)", size=30, weight="bold"),
        opponent_text,
        ft.Container(content=table_row, padding=20, bgcolor=ft.Colors.WHITE10, border_radius=10),
        ft.Container(content=info_text, alignment=ft.Alignment(0, 0)),
        ft.Container(content=hand_row, padding=20),
        ft.Row([knock_button, draw_button, play_button], alignment="center", spacing=20)
    ], expand=True, horizontal_alignment="center")