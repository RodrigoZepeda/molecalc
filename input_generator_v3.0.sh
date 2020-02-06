#!/bin/bash

#---------------------------------------------------------------------------#
# El programa crea los archivos de entrada de gaussian16 para calcular las  #
# energias involucradas en el ciclo de Born-Haber y los manda a correr      #
#---------------------------------------------------------------------------#
#
#
#
# Lee las variables de entrada de un archivo input (.var) en la primera entrada de la de la Shell $1
# para hacer los calculos a un conjunto de moleculas

Vertical=$(grep  Vertical: $1.var | awk '{print $2}')
Method=$(grep  Method: $1.var | awk '{print $2}')                       #Options=PM7,B3LYP,wB97XD,... Nota: Especificar U antes del funcional si es capa abierta, ej: UB3LYP
Base=$(grep  Base: $1.var | awk '{print $2}')                           #Nota: Si el metodo es PM7 no hay que especificar base, puede dejarse en blanco o con cualquier base
SP_Opt=$(grep  SP_Opt: $1.var | awk '{print $2}')                       #Options=SP,Opt
GP_Solvent=$(grep  GP_Solvent: $1.var | awk '{print $2}')               #Options=GP,Solvent. Nota: El metodo por default es PCM en agua. Si se requiere otro mtodo/disolvente hay que modificar el script 
scrf=$(grep  scrf: $1.var | awk '{print $2}')
nproc=$(grep  nproc: $1.var | awk '{print $2}')

Coordinates_dir=$2
#---------------------------------------------------------------------------
# Inicializa las variables, identifica los casos posibles para las corridas
# y crea la etiqueta para el nombre del trabajo

# Lee el directorio de inicio
directory=$(pwd)

# Lee el metodo que se utilizara y determina si necesita una base (caso cuantico) o no (PM7)
case ${Method} in
        PM7) Base='' && mark_base='PM7';;
        PM6) Base='' && mark_base='PM6';;
        B3LYP) Base=$(grep  Base: $1.var | awk '{print $2}') && Base_head='/'${Base}
               mark_base='B3';;
        *) Base=$(grep  Base: $1.var | awk '{print $2}') && Base_head='/'${Base};;
esac

# Lee si se hara una optimizacion (Opt) o un single point (SP) y asigna nomenclatura
case ${SP_Opt} in
        SP) mark_spopt='SP' && spopt_head='';;
        Opt) mark_spopt='' && spopt_head=' Opt=(maxcyc=200,calcFC)';;
esac

# Lee si se usara fase gas (GP) o solvente (Solvent) y asigna nomenclatura
case ${GP_Solvent} in
        GP) mark_gpsolv='GP' && gpsolv_head='';;
        Solvent) mark_gpsolv='Sol' && gpsolv_head=' scrf=('${scrf}')';;
esac

case ${Vertical} in
        0) mark_vO='' && mark_vR=''
            input_header='# '${Method}${Base_head}${spopt_head}${gpsolv_head}' scf=xqc Freq output=wfn';;
        
        1) mark_vO='SP' && mark_vR='SP'
            input_header='# '${Method}${Base_head}${spopt_head}${gpsolv_head}' scf=xqc Freq output=wfn geom=check';;
esac

# Crea la entrada del input file para gaussian (archivo.gjf) segun los parametros leidos del archivo de entrada (.var)



#---------------------------------------------------------------------------
# Lee un archivo de entrada y declara las variables para el nombre ($Name $New_Name), carga ($Charge),
# multiplicidad  ($Multiplicity), el archivo de entrada debe tener 5 columnas con el formato: $Name   $ChargeOx   $MultOx   $ChargeRed   $MultRed.
#
#Asigna los archivos con las estructuras oxidadas crea los inputs
for mark_oxred in 'Ox'${mark_vO} 'Red'${mark_vR}
do
    # Crea la etiqueta para el nombre de los archivos
    label=${mark_base}${mark_gpsolv}${mark_oxred}

    while read -r  line
    do
        case ${mark_oxred} in
            Ox)
                Charge=$(echo $line | awk '{print $2}')
                Multiplicity=$(echo $line | awk '{print $3}')
                Name=$(echo $line | awk '{print $1}')
                New_Name=$(echo $line | awk '{print $1}')'_'${label}
                Name_chk=${Name}'_'${mark_base}${mark_gpsolv}'Ox';;
            Red)
                Charge=$(echo $line | awk '{print $4}')
                Multiplicity=$(echo $line | awk '{print $5}')
                Name=$(echo $line | awk '{print $1}')
                New_Name=$(echo $line | awk '{print $1}')'_'${label}
                Name_chk=${Name}'_'${mark_base}${mark_gpsolv}'Red';;
            OxSP)
                Charge=$(echo $line | awk '{print $4}')
                Multiplicity=$(echo $line | awk '{print $5}')
                Name=$(echo $line | awk '{print $1}')
                New_Name=$(echo $line | awk '{print $1}')'_'${label}
                Name_chk=${Name}'_'${mark_base}${mark_gpsolv}'Ox';;
            RedSP)
                Charge=$(echo $line | awk '{print $2}')
                Multiplicity=$(echo $line | awk '{print $3}')
                Name=$(echo $line | awk '{print $1}')
                New_Name=$(echo $line | awk '{print $1}')'_'${label}
                Name_chk=${Name}'_'${mark_base}${mark_gpsolv}'Red';;
        esac
        
        mkdir -p ${directory}/${Name}
        work_dir=${directory}/${Name}
        echo 'creating directory:'
        echo ${work_dir}
                    
#		Escribe el archivo input (.gjf) para gaussian (moleculas oxidadas) y manda las corridas en Miztli
        
        echo '%chk='${Name_chk}.chk > ${work_dir}/${New_Name}.gjf
        echo '%mem=60Gb' >> ${work_dir}/${New_Name}.gjf
        echo '%nproc'=${nproc} >> ${work_dir}/${New_Name}.gjf
        echo ${input_header} >> ${work_dir}/${New_Name}.gjf
        echo '' >> ${work_dir}/${New_Name}.gjf
        echo Title >> ${work_dir}/${New_Name}.gjf
        echo '' >> ${work_dir}/${New_Name}.gjf
        echo ${Charge}' '${Multiplicity} >> ${work_dir}/${New_Name}.gjf
        
        if [ ${Vertical} -eq  '0' ]
               
          then     
               sed '1,2d' ${Coordinates_dir}/${Name}.xyz >> ${work_dir}/${New_Name}.gjf
               echo '' >> ${work_dir}/${New_Name}.gjf
          
          elif [ ${Vertical} -eq  '1' ]
          then
               echo '' >> ${work_dir}/${New_Name}.gjf
                   
          fi
                
        echo ${New_Name}.wfn >> ${work_dir}/${New_Name}.gjf
        echo '' >> ${work_dir}/${New_Name}.gjf
		
 

# 		Escribe en pantalla todas las moleculas, las propiedades y los parametros  de la corrida
    	echo ${New_Name}
        echo '         Charge: '${Charge}
        echo '   Multiplicity: '${Multiplicity}
        echo '          INPUT: '${Method} ${Base} ${SP_Opt} ${GP_Solvent}
        echo '         HEADER: '${input_header}
    
    done < $1.inchm
done 