import flet as ft
from utils.deck import Deck
from utils.component import create_ui_card

def calculate_score(hand):
    score = sum(c.value for c in hand)
    # Gestion de l'As : vaut 11 par défaut, mais passe à 1 si on dépasse 21
    aces = sum(1 for c in hand if c.rank == 'A')
    while score > 21 and aces > 0:
        score -= 10
        aces -= 1
    return score

def get_game_view():
    deck = Deck()
    player_hand, dealer_hand = [], []
    game_over = False
    status_msg = "À vous de jouer !"

    # Composants UI
    dealer_row = ft.Row(spacing=10, alignment=ft.MainAxisAlignment.CENTER)
    player_row = ft.Row(spacing=10, alignment=ft.MainAxisAlignment.CENTER)
    status_text = ft.Text(status_msg, size=20, weight="bold")
    dealer_score_text = ft.Text("Score : ?", size=16)
    player_score_text = ft.Text("Score : 0", size=16)

    def update_ui(show_dealer=False):
        # Mise à jour main Joueur
        player_row.controls = [create_ui_card(c) for c in player_hand]
        player_score_text.value = f"Score : {calculate_score(player_hand)}"
        
        # Mise à jour main Croupier
        if show_dealer:
            dealer_row.controls = [create_ui_card(c) for c in dealer_hand]
            dealer_score_text.value = f"Score : {calculate_score(dealer_hand)}"
        else:
            # Cache la première carte du croupier
            dealer_row.controls = [create_ui_card(None), create_ui_card(dealer_hand[1])]
            dealer_score_text.value = "Score : ?"
        
        status_text.value = status_msg
        
    def hit(e):
        nonlocal game_over, status_msg
        if not game_over:
            player_hand.append(deck.draw())
            if calculate_score(player_hand) > 21:
                status_msg = "Bust ! Vous avez perdu."
                game_over = True
                update_ui(show_dealer=True)
            else:
                update_ui()
            e.page.update()

    def stand(e):
        nonlocal game_over, status_msg
        if not game_over:
            game_over = True
            # IA du Croupier : tire tant qu'il est en dessous de 17
            while calculate_score(dealer_hand) < 17:
                dealer_hand.append(deck.draw())
            
            p_score = calculate_score(player_hand)
            d_score = calculate_score(dealer_hand)
            
            if d_score > 21: status_msg = "Le croupier a sauté ! VICTOIRE !"
            elif p_score > d_score: status_msg = "VICTOIRE !"
            elif p_score < d_score: status_msg = "DÉFAITE !"
            else: status_msg = "ÉGALITÉ (Push) !"
            
            update_ui(show_dealer=True)
            e.page.update()

    def reset(e):
        nonlocal deck, player_hand, dealer_hand, game_over, status_msg
        deck = Deck()
        player_hand = [deck.draw(), deck.draw()]
        dealer_hand = [deck.draw(), deck.draw()]
        game_over = False
        status_msg = "À vous de jouer !"
        update_ui()
        e.page.update()

    # Initialisation
    player_hand = [deck.draw(), deck.draw()]
    dealer_hand = [deck.draw(), deck.draw()]
    update_ui()

    return ft.Column([
        ft.Text("Blackjack Casino", size=30, weight="bold"),
        ft.Divider(),
        ft.Text("Main du Croupier", weight="bold"),
        dealer_score_text,
        dealer_row,
        ft.Container(height=30),
        ft.Text("Votre Main", weight="bold"),
        player_score_text,
        player_row,
        ft.Divider(),
        ft.Container(content=status_text, alignment=ft.Alignment(0, 0)),
        ft.Row([
            ft.ElevatedButton("Tirer (Hit)", on_click=hit, bgcolor=ft.Colors.GREEN_800),
            ft.ElevatedButton("Rester (Stand)", on_click=stand, bgcolor=ft.Colors.BLUE_800),
            ft.OutlinedButton("Rejouer", on_click=reset),
        ], alignment=ft.MainAxisAlignment.CENTER)
    ], scroll=ft.ScrollMode.AUTO, expand=True)