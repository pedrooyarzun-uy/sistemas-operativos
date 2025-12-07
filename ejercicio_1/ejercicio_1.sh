#!/bin/bash

usuarios="usuarios.txt"
productos="productos.txt"
datos_dir="Datos"
datos_reporte="$datos_dir/datos.CSV"
usuario_logueado=""
esta_corriendo=true
tipos_validos=(base layer shade dry contrast technical texture mediums)
codigos_validos=(BAS LAY SHA DRY CON TEC TEX MED)

if [ ! -f "$usuarios" ]; then
    echo "admin:admin" > "$usuarios"
fi
if [ ! -f "$productos" ]; then
    > "$productos"
fi

crear_usuario() {
    echo "-- Crear usuario --"
    usuario_valido=false
    while [ "$usuario_valido" = false ]; do
        read -p "Ingrese nombre de usuario: " nuevo_usuario
        if [ -z "$nuevo_usuario" ]; then
            echo "El nombre de usuario no puede estar vacío."
            continue
        fi
        if [[ "$nuevo_usuario" == *:* ]]; then
            echo "El nombre de usuario no puede contener ':'."
            continue
        fi

        if grep -q "^${nuevo_usuario}:" "$usuarios"; then
            echo "El usuario '$nuevo_usuario' ya existe."
            continue
        fi
        usuario_valido=true
    done
    pass_valida=false
    while [ "$pass_valida" = false ]; do
        read -s -p "Ingrese contraseña: " nueva_pass
        echo
        if [ -z "$nueva_pass" ]; then
            echo "La contraseña no puede estar vacía."
            continue
        fi
        pass_valida=true
    done
    echo "${nuevo_usuario}:${nueva_pass}" >> "$usuarios"
    echo "Usuario '$nuevo_usuario' creado correctamente."
}

cambiar_contrasena() {
    echo "-- Cambiar contraseña --"
    pass_valida=false
    while [ "$pass_valida" = false ]; do
        read -s -p "Ingrese nueva contraseña: " nueva_pass
        echo
        if [ -z "$nueva_pass" ]; then
            echo "La contraseña no puede estar vacía."
            continue
        fi
        pass_valida=true
    done

    tmp=$(mktemp)
    sed "s/^${usuario_logueado}:.*/${usuario_logueado}:${nueva_pass}/" "$usuarios" > "$tmp" \
        && mv "$tmp" "$usuarios"
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

    tipo_valido=false
    while [ "$tipo_valido" = false ]; do
        read -p "Tipo: " tipo

        if [ -z "$tipo" ]; then
            echo "El tipo no puede estar vacío."
            continue
        fi

        tipo_normalizado=$(echo "$tipo" | tr '[:upper:]' '[:lower:]')

        es_conocido=false
        for t in "${tipos_validos[@]}"; do
            if [ "$tipo_normalizado" = "$t" ]; then
                es_conocido=true
                tipo_esperado="$t"
                break
            fi
        done

        if [ "$es_conocido" = false ]; then
            echo "Tipo inválido."
            echo "Los tipos válidos son:"
            printf " - %s\n" "base" "layer" "shade" "dry" "contrast" "technical" "texture" "mediums"
            continue
        fi
        tipo="$tipo_esperado"
        tipo_valido=true
    done
    codigo=$(echo "$tipo" | awk '{print toupper(substr($0,1,3))}')
    modelo_valido=false
    while [ "$modelo_valido" = false ]; do
        read -p "Modelo: " modelo
        if [ -z "$modelo" ]; then
            echo "El modelo no puede estar vacío."
        else
            modelo_valido=true
        fi
    done

    descripcion_valida=false
    while [ "$descripcion_valida" = false ]; do
        read -p "Descripción: " descripcion
        if [ -z "$descripcion" ]; then
            echo "La descripción no puede estar vacía."
        else
            descripcion_valida=true
        fi
    done

    cantidad_valida=false
    while [ "$cantidad_valida" = false ]; do
        read -p "Cantidad: " cantidad
        if ! [[ "$cantidad" =~ ^[0-9]+$ ]]; then
            echo "La cantidad debe ser un entero no negativo."
        else
            cantidad_valida=true
        fi
    done

    precio_valido=false
    while [ "$precio_valido" = false ]; do
        read -p "Precio unitario (entero): " precio
        if ! [[ "$precio" =~ ^[0-9]+$ ]]; then
            echo "El precio debe ser un entero no negativo."
        else
            precio_valido=true
        fi
    done

    if grep -q "^${codigo} - ${tipo} - ${modelo} - " "$productos"; then
        echo "Ya existe un producto con el mismo código, tipo y modelo."
        return
    fi

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


vender_producto() {
    echo "-- Vender producto --"
    if [ ! -s "$productos" ]; then
        echo "No hay productos cargados."
        return
    fi
    lista_productos=()
    while IFS= read -r linea; do
        [ -z "$linea" ] && continue
        lista_productos+=("$linea")
    done < "$productos"
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

    carrito=()
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
        printf -- "- %s - %s | Cantidad: %d | Total: $%d\n" "${tipos[idx]}" "${modelos[idx]}" "$cantidad_vendida" "$subtotal"
        nueva_cantidad=$((cantidades[idx] - cantidad_vendida))
        lineas_actualizadas[idx]="${codigos[idx]} - ${tipos[idx]} - ${modelos[idx]} - ${descripciones[idx]} - ${nueva_cantidad} - \$ ${precios[idx]}"
    done
    printf "%s\n" "${lineas_actualizadas[@]}" > "$productos"
    echo "Total general: \$${total_general}"
}

crear_reporte() {
    echo "-- Crear reporte de pinturas --"
    if [ ! -s "$productos" ]; then
        echo "No hay productos cargados."
        return
    fi

    mkdir -p "$datos_dir"
    echo "codigo,tipo,modelo,descripcion,cantidad,precio" > "$datos_reporte"
    registros=0

    while IFS= read -r linea; do
        [ -z "$linea" ] && continue
        IFS=' - ' read -r codigo tipo modelo descripcion cantidad resto <<< "$linea"
        precio="${resto#\$ }"
        printf "%s,%s,%s,%s,%s,%s\n" "$codigo" "$tipo" "$modelo" "$descripcion" "$cantidad" "$precio" >> "$datos_reporte"
        registros=$((registros + 1))
    done < "$productos"

    if [ "$registros" -eq 0 ]; then
        echo "No se encontraron productos para reportar. Se generó el archivo solo con encabezado."
    else
        echo "Reporte generado en '$datos_reporte' con $registros registro(s)."
    fi
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
            5) vender_producto ;;
            7) crear_reporte ;;
            8) echo "Saliendo..."; esta_corriendo=false ;;
            *) echo "Opción no válida." ;;
        esac
        echo ""
    done
done
