import flet as ft

def create_ui_card(card_obj):
    if not card_obj:
        return ft.Container(width=80, height=120, border=ft.border.all(1, ft.Colors.WHITE24), border_radius=5)
    
    return ft.Container(
        content=ft.Column(
            [
                ft.Text(card_obj.rank, size=20, weight="bold", color=card_obj.color),
                ft.Text(card_obj.suit, size=30, color=card_obj.color),
            ],
            alignment=ft.MainAxisAlignment.CENTER,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
        ),
        width=80,
        height=120,
        bgcolor=ft.Colors.WHITE,
        border_radius=10,
       alignment=ft.Alignment(0, 0),
    )