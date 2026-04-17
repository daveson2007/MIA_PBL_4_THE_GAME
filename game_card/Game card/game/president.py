import flet as ft
from utils.deck import Deck
from utils.component import create_ui_card

# Hiérarchie officielle du Président : 3 est le plus faible, 2 est le plus fort
PRESIDENT_RANK_VALUE = {
    '3': 1, '4': 2, '5': 3, '6': 4, '7': 5, '8': 6, '9': 7, 
    '10': 8, 'V': 9, 'D': 10, 'R': 11, 'A': 12, '2': 13
}

def get_game_view():
    deck = Deck()
    # On distribue toutes les cartes (52 / 4 joueurs = 13 cartes)
    player_hand = sorted([deck.draw() for _ in range(13)], key=lambda x: PRESIDENT_RANK_VALUE[x.rank])
    ai_hands = [ [deck.draw() for _ in range(13)] for _ in range(3) ]
    
    table = [] # Cartes actuellement sur la table
    status_msg = "Votre tour. Jouez une carte plus forte que la table."
    selected_card_index = None

    table_row = ft.Row(spacing=10, alignment=ft.MainAxisAlignment.CENTER)
    player_hand_row = ft.Row(wrap=True, spacing=5, alignment=ft.MainAxisAlignment.CENTER)
    status_text = ft.Text(status_msg, italic=True)

    def update_ui():
        # Affichage de la table
        table_row.controls = [create_ui_card(c) for c in table]
        
        # Affichage de la main du joueur
        player_hand_row.controls.clear()
        for i, card in enumerate(player_hand):
            is_selected = (selected_card_index == i)
            card_ui = create_ui_card(card)
            if is_selected:
                card_ui.border = ft.border.all(3, ft.Colors.AMBER)
                card_ui.offset = ft.Offset(0, -0.1)
            
            player_hand_row.controls.append(
                ft.GestureDetector(
                    content=card_ui,
                    on_tap=lambda e, idx=i: select_card(idx, e.page)
                )
            )
        status_text.value = status_msg

    def select_card(index, page):
        nonlocal selected_card_index
        selected_card_index = index
        update_ui()
        page.update()

    def play_card(e):
        nonlocal selected_card_index, table, status_msg
        if selected_card_index is not None:
            card = player_hand[selected_card_index]
            
            # Vérification de la règle : carte plus forte que la table
            current_table_val = PRESIDENT_RANK_VALUE[table[-1].rank] if table else 0
            if PRESIDENT_RANK_VALUE[card.rank] > current_table_val:
                table.append(player_hand.pop(selected_card_index))
                selected_card_index = None
                status_msg = "Bien joué ! Au tour de l'IA..."
                update_ui()
                e.page.update()
                # Simuler tour IA après un court délai
                ai_turn(e.page)
            else:
                status_msg = "Action impossible : Carte trop faible !"
                e.page.update()

    def pass_turn(e):
        nonlocal table, status_msg
        table = [] # Dans cette version simple, passer nettoie la table
        status_msg = "Vous passez. La table est nettoyée."
        ai_turn(e.page)

    def ai_turn(page):
        # Logique IA simplifiée : joue la plus petite carte possible qui bat la table
        nonlocal table, status_msg
        import time
        time.sleep(1) # Simulation de réflexion
        
        current_val = PRESIDENT_RANK_VALUE[table[-1].rank] if table else 0
        ai_played = False
        
        for i, ai_hand in enumerate(ai_hands):
            ai_hand.sort(key=lambda x: PRESIDENT_RANK_VALUE[x.rank])
            for idx, card in enumerate(ai_hand):
                if PRESIDENT_RANK_VALUE[card.rank] > current_val:
                    table.append(ai_hand.pop(idx))
                    ai_played = True
                    status_msg = f"L'IA {i+1} a joué un {card.rank}."
                    break
            if ai_played: break
        
        if not ai_played:
            table = []
            status_msg = "Toutes les IA ont passé. La table est vide !"
            
        update_ui()
        page.update()

    update_ui()

    return ft.Column([
        ft.Text("Le Président", size=30, weight="bold"),
        ft.Text("Objectif : Se débarrasser de ses cartes en premier.", size=14),
        ft.Divider(),
        ft.Text("Table", weight="bold"),
        ft.Container(content=table_row, height=150, bgcolor=ft.Colors.WHITE10, border_radius=10),
        ft.Divider(),
        ft.Text("Votre Main (Triée)", weight="bold"),
        player_hand_row,
        ft.Container(content=status_text, alignment=ft.Alignment(0, 0), padding=10),
        ft.Row([
            ft.ElevatedButton("Jouer la carte", on_click=play_card, icon="play_arrow"),
            ft.OutlinedButton("Passer / Nettoyer", on_click=pass_turn),
        ], alignment=ft.MainAxisAlignment.CENTER)
    ], scroll=ft.ScrollMode.AUTO, expand=True)