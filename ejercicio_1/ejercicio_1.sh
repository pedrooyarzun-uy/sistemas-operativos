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

filtrar_productos() {
    echo "-- Filtrar productos --"
    if [ ! -s "$productos" ]; then
        echo "No hay productos cargados."
        return
    fi

    pedir_filtro=true

    while [ "$pedir_filtro" = true ]; do

        read -p "Ingrese tipo para filtrar (Enter para todos): " filtro_tipo
        filtro_normalizado=$(echo "$filtro_tipo" | tr '[:upper:]' '[:lower:]')
        encontrados=0

        while IFS= read -r linea; do
            [ -z "$linea" ] && continue
            IFS=' - ' read -r codigo tipo modelo descripcion cantidad resto <<< "$linea"
            precio="${resto#\$ }"
            tipo_normalizado=$(echo "$tipo" | tr '[:upper:]' '[:lower:]')
            if [ -n "$filtro_tipo" ] && [ "$tipo_normalizado" != "$filtro_normalizado" ]; then
                continue
            fi
            printf "%s - %s - %s - %s - Stock: %s - $%s\n" "$codigo" "$tipo" "$modelo" "$descripcion" "$cantidad" "$precio"
            encontrados=1
        done < "$productos"

        if [ "$encontrados" -eq 0 ]; then
            if [ -z "$filtro_tipo" ]; then
                echo "No hay productos para mostrar."
            else
                echo "No se encontraron productos para el tipo '$filtro_tipo'."
            fi
        else
            pedir_filtro=false
        fi
        echo
    done
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
            6) filtrar_productos ;;
            8) echo "Saliendo..."; esta_corriendo=false ;;
            *) echo "Opción no válida." ;;
        esac
        echo ""
    done
done
