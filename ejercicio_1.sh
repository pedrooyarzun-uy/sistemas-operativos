#!/bin/bash

usuarios="usuarios.txt"

if [ ! -f "$usuarios" ]; then
    echo "admin:admin" > "$usuarios"
fi

crear_usuario() {
    echo "-- Crear usuario --"
    read -p "Ingrese nombre de usuario: " nuevo_usuario
    if [ -z "$nuevo_usuario" ]; then
        echo "El nombre de usuario no puede estar vacío."
        return
    fi
    if [[ "$nuevo_usuario" == *:* ]]; then
        echo "El nombre de usuario no puede contener ':'"
        return
    fi
    if grep -q "^${nuevo_usuario}:" "$usuarios"; then
        echo "El usuario '$nuevo_usuario' ya existe."
        return
    fi
    read -s -p "Ingrese contraseña: " nueva_pass
    echo
    if [ -z "$nueva_pass" ]; then
        echo "La contraseña no puede estar vacía."
        return
    fi
    echo "${nuevo_usuario}:${nueva_pass}" >> "$usuarios"
    echo "Usuario '$nuevo_usuario' creado correctamente."
}     

mostrarMenu() {
    echo "====================================="
    echo "   SISTEMA DE CONTROL DE INVENTARIO"
    echo "====================================="
    echo "1) Crear usuario"
    echo "2) Cambiar contraseña"
    echo "3) Login"
    echo "4) Logout"
    echo "5) Ingresar producto"
    echo "6) Vender producto"
    echo "7) Filtrar productos"
    echo "8) Crear reporte de pinturas"
    echo "9) Salir"
    echo "====================================="
}

while true; do
    mostrarMenu
    read -p "Seleccione una opción: " opcion

    case "$opcion" in
        1) crear_usuario ;;
        9) echo "Saliendo..."; exit 0 ;;
        *) echo "Opción no válida." ;;
    esac

    echo ""
done

