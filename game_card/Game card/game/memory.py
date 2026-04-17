import flet as ft
import random
import time
from utils.component import create_ui_card
from utils.deck import Card

def get_game_view():
    # Préparation des paires (8 paires pour une grille de 16)
    suits = ['♥', '♠', '♦', '♣']
    ranks = ['A', 'R', 'D', 'V', '10', '9', '8', '7']
    
    # Création de 8 paires de cartes
    base_cards = [Card(random.choice(suits), r, 0) for r in ranks]
    game_cards = base_cards + [Card(c.suit, c.rank, 0) for c in base_cards]
    random.shuffle(game_cards)

    # État du jeu
    revealed = [False] * 16
    matched = [False] * 16
    first_selection = None # Index de la première carte retournée
    waiting = False # Empêche de cliquer pendant l'animation de retournement

    grid = ft.GridView(expand=1, runs_count=4, spacing=10, run_spacing=10)
    status_text = ft.Text("Trouvez toutes les paires !", size=20, weight="bold")

    def on_card_click(e, index):
        nonlocal first_selection, waiting
        
        if waiting or revealed[index] or matched[index]:
            return

        # Révéler la carte
        revealed[index] = True
        update_grid()
        e.page.update()

        if first_selection is None:
            first_selection = index
        else:
            # Deuxième carte retournée
            if game_cards[first_selection].rank == game_cards[index].rank:
                # C'est une paire !
                matched[first_selection] = True
                matched[index] = True
                first_selection = None
                if all(matched):
                    status_text.value = "Félicitations ! Vous avez gagné !"
            else:
                # Pas une paire, on attend un peu avant de retourner
                waiting = True
                e.page.update()
                time.sleep(1)
                revealed[first_selection] = False
                revealed[index] = False
                first_selection = None
                waiting = False
            
            update_grid()
            e.page.update()

    def update_grid():
        grid.controls.clear()
        for i in range(16):
            if revealed[i] or matched[i]:
                # Affiche la face de la carte
                card_content = create_ui_card(game_cards[i])
            else:
                # Dos de la carte
                card_content = ft.Container(
                    content=ft.Icon(icon="question_mark", color=ft.Colors.WHITE),
                    width=80, height=120,
                    bgcolor=ft.Colors.BLUE_GREY_900,
                    border_radius=10,
                  alignment=ft.Alignment(0, 0),
                )
            
            grid.controls.append(
                ft.GestureDetector(
                    content=card_content,
                    on_tap=lambda e, idx=i: on_card_click(e, idx)
                )
            )

    def reset_game(e):
        nonlocal revealed, matched, first_selection, waiting
        random.shuffle(game_cards)
        revealed = [False] * 16
        matched = [False] * 16
        first_selection = None
        waiting = False
        status_text.value = "Trouvez toutes les paires !"
        update_grid()
        e.page.update()

    update_grid()

    return ft.Column([
        ft.Text("Memory", size=30, weight="bold"),
        status_text,
        ft.Divider(),
        ft.Container(content=grid, width=400, height=600, alignment=ft.Alignment(0, 0)),
        ft.ElevatedButton("Réinitialiser", on_click=reset_game)
    ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, expand=True)