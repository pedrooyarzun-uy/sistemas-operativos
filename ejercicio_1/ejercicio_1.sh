#!/bin/bash

usuarios="usuarios.txt"
productos="productos.txt"
usuario_logueado=""
esta_corriendo=true

if [ ! -f "$usuarios" ]; then
    echo "admin:admin" > "$usuarios"
fi
if [ ! -f "$productos" ]; then
    > "$productos"
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

cambiar_contrasena() {
    echo "-- Cambiar contraseña --"
    read -s -p "Ingrese nueva contraseña: " nueva_pass
    echo
    if [ -z "$nueva_pass" ]; then
        echo "La contraseña no puede estar vacía."
        return
    fi
    sed -i "s/^${usuario_logueado}:.*/${usuario_logueado}:${nueva_pass}/" "$usuarios"
    echo "Contraseña actualizada correctamente para '$usuario_logueado'."
}

login() {
    echo "-- Login --"
    read -p "Ingrese nombre de usuario: " usuario
    if ! grep -q "^${usuario}:" "$usuarios"; then
        echo "El usuario '$usuario' no existe."
        return
    fi
    pass_guardada=$(grep "^${usuario}:" "$usuarios" | cut -d':' -f2)
    read -s -p "Ingrese contraseña: " pass_ingresada
    echo
    if [ "$pass_guardada" = "$pass_ingresada" ]; then
        usuario_logueado="$usuario"
        echo "Bienvenido, $usuario_logueado."
    else
        echo "Contraseña incorrecta."
    fi
}

logout() {
    usuario="$usuario_logueado"
    usuario_logueado=""
    echo "Sesión cerrada de '$usuario'."
}

ingresar_producto() {
    echo "-- Ingresar producto --"
    read -p "Tipo: " tipo
    if [ -z "$tipo" ]; then
        echo "El tipo no puede estar vacío."
        return
    fi
    read -p "Modelo: " modelo
    if [ -z "$modelo" ]; then
        echo "El modelo no puede estar vacío."
        return
    fi
    read -p "Descripción: " descripcion
    if [ -z "$descripcion" ]; then
        echo "La descripción no puede estar vacía."
        return
    fi
    read -p "Cantidad: " cantidad
    if ! [[ "$cantidad" =~ ^[0-9]+$ ]]; then
        echo "La cantidad debe ser un entero no negativo."
        return
    fi
    read -p "Precio unitario (entero): " precio
    if ! [[ "$precio" =~ ^[0-9]+$ ]]; then
        echo "El precio debe ser un entero no negativo."
        return
    fi
    codigo=$(echo "$tipo" | awk '{print toupper(substr($0,1,3))}')
    linea="${codigo} - ${tipo} - ${modelo} - ${descripcion} - ${cantidad} - \$ ${precio}"
    echo "$linea" >> "$productos"
    echo "Producto ingresado: $linea"
}

vender_producto() {
    echo "-- Vender producto --"
    if [ ! -s "$productos" ]; then
        echo "No hay productos cargados."
        return
    fi
    mapfile -t lista_productos < "$productos"
    if [ "${#lista_productos[@]}" -eq 0 ]; then
        echo "No hay productos cargados."
        return
    fi

    declare -a codigos tipos modelos descripciones cantidades precios lineas_actualizadas
    for idx in "${!lista_productos[@]}"; do
        linea="${lista_productos[$idx]}"
        IFS=' - ' read -r codigo tipo modelo descripcion cantidad resto <<< "$linea"
        precio="${resto#\$ }"
        codigos[idx]="$codigo"
        tipos[idx]="$tipo"
        modelos[idx]="$modelo"
        descripciones[idx]="$descripcion"
        cantidades[idx]="$cantidad"
        precios[idx]="$precio"
        lineas_actualizadas[idx]="$linea"
    done

    echo "Productos disponibles:"
    for idx in "${!lista_productos[@]}"; do
        numero=$((idx + 1))
        printf "%d) %s - %s - $%s (Stock: %s)\n" "$numero" "${tipos[idx]}" "${modelos[idx]}" "${precios[idx]}" "${cantidades[idx]}"
    done

    declare -A carrito
    while true; do
        read -p "Número de producto (Enter para finalizar): " numero
        if [ -z "$numero" ]; then
            break
        fi
        if ! [[ "$numero" =~ ^[0-9]+$ ]] || [ "$numero" -lt 1 ] || [ "$numero" -gt "${#lista_productos[@]}" ]; then
            echo "Número inválido."
            continue
        fi
        idx=$((numero - 1))
        stock_disponible=$((cantidades[idx] - ${carrito[$idx]:-0}))
        if [ "$stock_disponible" -le 0 ]; then
            echo "No hay stock disponible para ${tipos[idx]} - ${modelos[idx]}."
            continue
        fi
        read -p "Cantidad a comprar (máximo $stock_disponible): " cantidad_compra
        if ! [[ "$cantidad_compra" =~ ^[0-9]+$ ]] || [ "$cantidad_compra" -le 0 ]; then
            echo "La cantidad debe ser un entero positivo."
            continue
        fi
        if [ "$cantidad_compra" -gt "$stock_disponible" ]; then
            echo "No puede superar el stock disponible."
            continue
        fi
        carrito[$idx]=$(( ${carrito[$idx]:-0} + cantidad_compra ))
        echo "Agregado: ${tipos[idx]} - ${modelos[idx]} x $cantidad_compra."
    done

    if [ "${#carrito[@]}" -eq 0 ]; then
        echo "No se seleccionó ningún producto."
        return
    fi

    total_general=0
    echo "Resumen de compra:"
    for idx in "${!carrito[@]}"; do
        cantidad_vendida=${carrito[$idx]}
        subtotal=$((cantidad_vendida * precios[idx]))
        total_general=$((total_general + subtotal))
        printf "- %s - %s | Cantidad: %d | Total: $%d\n" "${tipos[idx]}" "${modelos[idx]}" "$cantidad_vendida" "$subtotal"
        nueva_cantidad=$((cantidades[idx] - cantidad_vendida))
        lineas_actualizadas[idx]="${codigos[idx]} - ${tipos[idx]} - ${modelos[idx]} - ${descripciones[idx]} - ${nueva_cantidad} - \$ ${precios[idx]}"
    done
    printf "%s\n" "${lineas_actualizadas[@]}" > "$productos"
    echo "Total general: \$${total_general}"
}

mostrarMenu() {
    echo "====================================="
    echo "   SISTEMA DE CONTROL DE INVENTARIO"
    echo "   Usuario: $usuario_logueado"
    echo "====================================="
    echo "1) Crear usuario"
    echo "2) Cambiar contraseña"
    echo "3) Logout"
    echo "4) Ingresar producto"
    echo "5) Vender producto"
    echo "6) Filtrar productos"
    echo "7) Crear reporte de pinturas"
    echo "8) Salir"
    echo "====================================="
}

while $esta_corriendo; do
    while [ -z "$usuario_logueado" ]; do
        login
    done

    while $esta_corriendo; do
        mostrarMenu
        read -p "Seleccione una opción: " opcion

        case "$opcion" in
            1) crear_usuario ;;
            2) cambiar_contrasena ;;
            3) logout 
                break
                ;;
            4) ingresar_producto ;;
            5) vender_producto ;;
            8) echo "Saliendo..."; esta_corriendo=false ;;
            *) echo "Opción no válida." ;;
        esac
        echo ""
    done
done
