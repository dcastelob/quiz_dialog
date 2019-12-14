#!/bin/bash

export G_QUESTION_PATH="questions"
export G_QUESTION="Selecione com a barra de espaço."




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

Q_ENUNCIADO=$(get_content "$G_QUESTION_PATH/sumary.txt" "INTRO")
RESP=$(yesno "${Q_ENUNCIADO}")
if [ "$?" -ne 0 ];then
    exit 1
fi

for FILE in $(ls -1 ${G_QUESTION_PATH}); do
    Q_ENUNCIADO=$(get_content "$G_QUESTION_PATH/$FILE" "PERGUNTA")
    Q_TIPO=$(get_content "$G_QUESTION_PATH/$FILE" "TIPO")
    Q_OPCOES=$(get_content "$G_QUESTION_PATH/$FILE" "OPT")
    Q_RESPOSTA=$(get_content "$G_QUESTION_PATH/$FILE" "RESPOSTA")
    
   # echo ${Q_ENUNCIADO}
    
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
        echo "Acertou"
    else
        echo "Errou"    
    fi
done


