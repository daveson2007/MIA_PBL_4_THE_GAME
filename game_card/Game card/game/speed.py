import flet as ft
import random
import time
from utils.deck import Deck
from utils.component import create_ui_card

SPEED_VALUES = {
    'A': 1, '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, 
    '8': 8, '9': 9, '10': 10, 'V': 11, 'D': 12, 'R': 13
}

def is_playable(card, target_card):
    if not card or not target_card: return False
    v1 = SPEED_VALUES[card.rank]
    v2 = SPEED_VALUES[target_card.rank]
    diff = abs(v1 - v2)
    return diff == 1 or diff == 12

def get_game_view():
    deck = Deck()
    player_hand = [deck.draw() for _ in range(5)]
    ai_hand = [deck.draw() for _ in range(5)]
    center_piles = [deck.draw(), deck.draw()]
    
    status_msg = ft.Text("Vite ! Posez vos cartes !", size=20)
    center_row = ft.Row(alignment=ft.MainAxisAlignment.CENTER, spacing=20)
    player_row = ft.Row(alignment=ft.MainAxisAlignment.CENTER, spacing=10)
    selected_card_idx = None

    # --- DÉFINITION DES FONCTIONS AVANT LE RETURN ---

    def update_ui():
        center_row.controls = [
            ft.Column([
                create_ui_card(center_piles[0]),
                ft.ElevatedButton("Poser ici", on_click=lambda e: play_to_pile(0, e))
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER),
            ft.Column([
                create_ui_card(center_piles[1]),
                ft.ElevatedButton("Poser ici", on_click=lambda e: play_to_pile(1, e))
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER)
        ]
        
        player_row.controls.clear()
        for i, card in enumerate(player_hand):
            card_ui = create_ui_card(card)
            if selected_card_idx == i:
                card_ui.border = ft.border.all(3, ft.Colors.YELLOW)
            
            player_row.controls.append(
                ft.GestureDetector(
                    content=card_ui,
                    on_tap=lambda e, idx=i: select_card(idx, e.page)
                )
            )

    def select_card(idx, page):
        nonlocal selected_card_idx
        selected_card_idx = idx
        update_ui()
        page.update()

    def play_to_pile(pile_idx, e):
        nonlocal selected_card_idx
        if selected_card_idx is not None:
            card = player_hand[selected_card_idx]
            if is_playable(card, center_piles[pile_idx]):
                center_piles[pile_idx] = player_hand.pop(selected_card_idx)
                new_card = deck.draw()
                if new_card: player_hand.append(new_card)
                selected_card_idx = None
                update_ui()
            e.page.update()

    def reset_piles(e):
        nonlocal center_piles
        c1, c2 = deck.draw(), deck.draw()
        if c1 and c2:
            center_piles = [c1, c2]
            update_ui()
            e.page.update()

    def ai_move(e):
        nonlocal ai_hand
        played = False
        for i, card in enumerate(ai_hand):
            for p_idx in range(2):
                if is_playable(card, center_piles[p_idx]):
                    center_piles[p_idx] = ai_hand.pop(i)
                    new_card = deck.draw()
                    if new_card: ai_hand.append(new_card)
                    played = True
                    break
            if played: break
        update_ui()
        e.page.update()

    # Initialisation de l'affichage
    update_ui()

    # --- LE RETURN EST BIEN À LA FIN ---
    return ft.Column([
        ft.Text("Speed", size=30, weight="bold"),
        status_msg,
        ft.Divider(),
        ft.Text("Adversaire (IA)", size=12),
        ft.Row([ft.Container(width=50, height=70, bgcolor=ft.Colors.BLUE_GREY_700, border_radius=5) for _ in ai_hand], alignment=ft.MainAxisAlignment.CENTER),
        center_row,
        ft.Text("Votre Main", weight="bold"),
        player_row,
        ft.Row([
            ft.TextButton("Bloqué ? Reset Piles", on_click=reset_piles),
            ft.ElevatedButton("Tour IA (Simuler)", on_click=ai_move)
        ], alignment=ft.MainAxisAlignment.CENTER)
    ], expand=True, horizontal_alignment=ft.CrossAxisAlignment.CENTER)