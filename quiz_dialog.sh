#!/bin/bash

export G_QUESTION_PATH="questions"
export G_QUESTION="Selecione com a barra de espaço."


function progress()
{
    ENUNCIADO="$1"
    OPTIONS="$2"
    
    CMD+="dialog  --stdout "
    CMD+=" --backtitle \"${G_BG_TEXT}\" --title \"Progresso do exame\""
    CMD+=" --gauge  \"${ENUNCIADO}\" 8 60 60"
    
    eval "${CMD}"
   # if [ "$?" -eq 1 ];then
   #     exit 1
   # fi
}

function single_select()
{
    ENUNCIADO="$1"
    OPTIONS="$2"
    IFS_OLD=IFS
    IFS=$'\n'
    for OP in ${OPTIONS}; do
        LETRA=$(echo "${OP}" | awk -F ";" '{print $1}')
        TEXTO=$(echo "${OP}" | awk -F ";" '{print $2}')
        OPT+="${LETRA} '${TEXTO}' off "
    done
    IFS=${IFS_OLD}
    
    CMD+="dialog  --stdout "
    CMD+=" --backtitle \"${G_BG_TEXT}\" --title \"${G_QUESTION}\""
    CMD+=" --radiolist \"${ENUNCIADO}\" 0 0 0 ${OPT}"

    #echo "${CMD}"
    eval "${CMD}"
    if [ "$?" -eq 1 ];then
        exit 1
    fi
}

function multi_select()
{
    ENUNCIADO="$1"
    OPTIONS="$2"
    IFS_OLD=IFS
    IFS=$'\n'
    for OP in ${OPTIONS}; do
        LETRA=$(echo "${OP}" | awk -F ";" '{print $1}')
        TEXTO=$(echo "${OP}" | awk -F ";" '{print $2}')
        OPT+="${LETRA} '${TEXTO}' off "
    done
    IFS=${IFS_OLD}
    
    CMD+="dialog  --stdout "
    CMD+=" --backtitle \"${G_BG_TEXT}\" --title \"${G_QUESTION}\""
    CMD+=" --checklist \"${ENUNCIADO}\" 0 0 0 ${OPT}"
    
    #echo "${CMD}"
    eval "${CMD}"
    if [ "$?" -eq 1 ];then
        exit 1
    fi
    
}

function text()
{
    ENUNCIADO="$1"
    dialog --stdout  --backtitle "${G_BG_TEXT}" --title "${G_QUESTION}" --inputbox "${ENUNCIADO}" 0 0
    #echo "A:$?"
    if [ "$?" -eq 1 ];then
        #echo "cancelou"
        exit 1
    fi

}

function yesno()
{
    ENUNCIADO="$1"
    dialog --stdout  --backtitle "${G_BG_TEXT}" --title "${G_QUESTION}" --yesno "${ENUNCIADO}" 10 80
 

}

function get_content()
{
    FILE="$1"
    STRING="$2"
    (cat "$FILE" | grep "^${STRING}" | awk -F"=" '{print $2}')
}



# INICIO


#NOME=$(text "Qual é o seu nome")
#echo "Meu nome é: $NOME"

#OPCOES=$(multi_select "Selecione varias opações")
#echo "Opções: $OPCOES"

#OPCOES=$(single_select "Selecione uma opação")
#echo "Opções: $OPCOES"


export G_BG_TEXT=$(get_content "$G_QUESTION_PATH/sumary.txt" "EXAME_TITLE")
export G_APROVACAO=$(get_content "$G_QUESTION_PATH/sumary.txt" "APROVACAO")

SUCESSO=0
TOTAL=$(ls -1 ${G_QUESTION_PATH}/q*.txt| wc -l)
COUNT=0

# Inicio do teste
Q_ENUNCIADO=$(get_content "$G_QUESTION_PATH/sumary.txt" "INTRO")
RESP=$(yesno "${Q_ENUNCIADO} Total de questões: $TOTAL")
if [ "$?" -ne 0 ];then
    exit 1
fi

for FILE in $(ls -1 ${G_QUESTION_PATH}/q*.txt); do
    Q_ENUNCIADO=$(get_content "$FILE" "PERGUNTA")
    Q_TIPO=$(get_content "$FILE" "TIPO")
    Q_OPCOES=$(get_content "$FILE" "OPT")
    Q_RESPOSTA=$(get_content "$FILE" "RESPOSTA")
    
   # echo ${Q_ENUNCIADO}
    echo "$FILE"
    case "${Q_TIPO}" in
        "SINGLE")
            RESP=$(single_select "${Q_ENUNCIADO}" "${Q_OPCOES}" "${Q_RESPOSTA}")
            #echo "$RESP"
            ;;
        "MULTI")
            RESP=$(multi_select "${Q_ENUNCIADO}" "${Q_OPCOES}" "${Q_RESPOSTA}")
            #echo "$RESP"
            ;;
        "TEXT")
            RESP=$(text "${Q_ENUNCIADO}" "${Q_OPCOES}" "${Q_RESPOSTA}")
            #echo "$RESP"
            ;;
    esac
    if [ "${RESP}" = "${Q_RESPOSTA}" ]; then
        SUCESSO=$(($SUCESSO+1))
        echo "Acertou"
    else
        echo "Errou"    
    fi
    COUNT=$(($COUNT+1))
    
    # Criando progresso de exame
    P=$(echo "scale=1; ${COUNT}/${TOTAL} *100" | bc | cut -d"." -f1)
    echo "${P}" | progress "Progresso do exame, ${COUNT} de ${TOTAL} questões. "
    sleep 2s
    
done

S=$(echo "scale=1; ${SUCESSO}/${TOTAL} *100" | bc | cut -d"." -f1)
if [ ${S} -gt ${G_APROVACAO} ];then
    MSG="Parabéns, você foi aprovado alcançando ${S}% do exame."
else
    MSG="Infelizmente você não foi aprovado, alcançou apenas ${S}% do exame."     
fi

RESP=$(yesno "Resultado - Total de questões: ${TOTAL}, Sucesso: ${SUCESSO}. Falha: $((${TOTAL}-${SUCESSO})) \n${MSG}")
if [ "$?" -ne 0 ];then
    exit 1
fi
