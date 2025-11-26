Creamos un loop infinito para mostrar el menu de opciones. 

crear usuario
guardamos el archivo usuarios.txt en la variable usuarios.
si el archivo no existe creamos el usuario admin por default
-f pregunta si el archivo exist y es un archivo (-e solo si existe)
-z verifica si una cadena está vacía
como usamos : para separar el nombre de la contraseña verificamos que el usuario no tenga :
verificamos que no exista el usuario
(-q de quiet, para que no imprima por pantalla las cosas que coincidan) ^ coincidencia al principio de la linea, el nuevo_usuario y los : para que sea commpleta (lucia: y no luciana)
```
echo "${nuevo_usuario}:${nueva_pass}" >> "$usuarios"
```
lo agrega al final del archivo

cambiar contraseña
verifica que el usuario exista
```
pass_actual=$(grep "^${usuario}:" "$usuarios" | cut -d':' -f2)
```
cut -> divide una linea en campos 
-d':' delimitador :
-f2 mostrame el segundo campo
si son diferentes no hago nada
verifico que no sea vacia
sed significa Stream EDitor.
-i viene de in-place (modificar el archivo directamente)
s/patrón_a_buscar/texto_de_reemplazo/


====== INGRESAR PRODUCTOS ========
```
if ! [[ "$cantidad" =~ ^[0-9]+$ ]]; then
```
=~ para comparar una cadena con una expresión regular
el + es por una o más repeticiones
$para que sean digitos hasta el final

```
codigo=$(echo "$tipo" | awk '{print toupper(substr($0,1,3))}')
```
awk sirve para recorrer archivos o cadenas y operar sobre líneas, columnas o texto.
substr($0,1,3) toma los primeros 3 caracteres de la línea.
toupper(...) los convierte a mayúsculas.

====== FILTRAR PRODUCTOS ======
```
if [ ! -s "$productos" ]; then
```
-s valida que exista y no esté vacío para evitar recorrer archivos vacíos.
`read -p "Ingrese tipo para filtrar (Enter para todos): "` permite ingresar el filtro opcional.
```
filtro_normalizado=$(echo "$filtro_tipo" | tr '[:upper:]' '[:lower:]')
```
con `tr` llevamos el texto a minúsculas y así comparamos sin depender de mayúsculas/minúsculas.
```
while IFS=' - ' read -r codigo tipo modelo descripcion cantidad resto
```
ajustamos `IFS` para separar cada columna según el formato de guardado y obtener cada campo con `read`.
`resto#\$ ` elimina el prefijo `$ `, dejando solo el valor del precio.
Si hay filtro, se compara la versión en minúsculas (`tipo_normalizado`) y se imprime con `printf` cada producto que coincide.
Cuando no encuentra coincidencias informa si no hay productos o si el tipo especificado no existe.
