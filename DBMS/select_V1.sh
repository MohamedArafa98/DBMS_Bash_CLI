#!/bin/bash
# Style the Connected Line
function db_connected() {
    db_name=$1
    typeset -i filler_length
    filler_length=(59-${#db_name})
    echo -n "| $(tput setaf 3)<$1 "
    for ((counter = 0; counter < filler_length; counter++)); do echo -n "-"; done
    echo " Connected>$(tput setaf 2) |"
}

function select_with_check() {

    #remove SQL specific words
    sql_line=$(echo "$entry" | sed -e 's/SELECT//g' -e 's/FROM//g' -e 's/WHERE//g' |
    sed -e 's/select//g' -e 's/from//g' -e 's/where//g')
    
    #get fields. No
    fields_no=$(echo "$sql_line" | awk -F';' 'END{print NF}')
    # (echo "$sql_line" | awk -F';' '{print $2}') 

    #get table and check its existance
    table_name=$(echo "$sql_line" | awk -F';' '{gsub(/^[ \t]+|[ \t]+$/, "",$2);print $2}') #strip fieled
    if [[ ! -f "$table_name" ]]; then echo "Error : Invalid Table Name" ; return; fi #check if the table file exists

    #get the selection column and check its existance
    select_column=$(echo "$sql_line" | awk -F';' '{gsub(/^[ \t]+|[ \t]+$/, "",$1);print $1}') #strip fieled
    select_column_field=$(awk -F'|' 'BEGIN{found=0} {if(NR==1){for(i=1;i<=NF;i++)
    {if($i=="'$select_column'")found=i}}} END{print found}' "$table_name") #check if the coulmn name exists in the table header
    
    
    if [[ $select_column_field == 0 ]]  && [[ $select_column != "*" ]]; #check if not all or invalid
    then echo "Error : Invalid Selected Column Name" && return; fi

    if ((fields_no == 3)); then
        if [ "$select_column" == "*" ]; then cat "$table_name"; #check if all columns are selected
        else awk 'BEGIN{FS="|"}{print $'"$select_column_field"' }' "$table_name" ; fi
        return
    else
        #get and check the where operator
        where_operator=$(echo "$sql_line" | awk -F';' '{print $3}' |
        sed -e 's/[a-zA-Z]*//g' -e 's/[0-9]*//g' -e's/ //g') #clean from all special expect for the arthimatic operators
        if ! [[ "$where_operator" =~ ^(==|>|<|>=|<=)$ ]] ; # Check if the entered value is not an operator
        then echo "Error : Invalid Where Operator"; return; fi # if not print invalid

        #get the column in the WHERE condition and check its existance
        where_column=$(echo "$sql_line" | awk -F';' '{print $3}' | awk -F''$where_operator'' '{gsub(/^[ \t]+|[ \t]+$/, "",$1);print $1}') # Use the where_operator which we just extracted as a seprator " before seprator as we used $1" to get the following column name after striping.
        where_column_field=$(awk -F'|' 'BEGIN{found=0} {if(NR==1){for(i=1;i<=NF;i++){if($i=="'$where_column'")found=i}}} END{print found}' "$table_name") #check if the column exists in the table and if yes then it will return the column name if no it will return zero
        if ((where_column_field == 0)); then echo "Error : Invalid Where Column Name"; return; fi #if found equals zero then it will print invalid

        # get the value in the WHERE condition and check its existance
        where_value=$(echo "$sql_line" | awk -F';' '{print $3}' | awk -F''$where_operator'' '{gsub(/^[ \t]+|[ \t]+$/, "",$2);print $2}') # Use the where_operator which we just extracted as a seprator " after seprator as we used $2" to get the following column name after striping.
        where_value_exist=$(awk -F'|' 'BEGIN{found=0} {if(NR!=1){if($"'$where_column_field'"=="'$where_value'")found=1}} END{print found}' "$table_name") #check if the value exists in the column and if yes then it will return 1 in the found variable
        if ((where_value_exist == 0)); then echo "Warning : The Where Value does not exist in the Table "; fi #if found equals zero then it will print invalid

        if [ "$select_column" == "*" ]; then awk  -v were_value="$where_value" -F'|' '{if(NR!=1){if($"'$where_column_field'" '$where_operator' were_value){print $0}}}' "$table_name" ; #checks if the column equals * ( all ) then check if each column value applies the arthimatic operation then print right line
        else awk -v were_value="$where_value" -F'|' '{if(NR!=1){if($'$where_column_field'  '$where_operator' were_value){print $'"$select_column_field"'}}}' "$table_name" ;fi
        # echo "select $select_column from $table_name where $where_column $where_operator $where_value"
    fi
}

clear
db_name=$1
while true; do
    tput setaf 2 #change font color to Green
    echo "+--------------------------------------------------------------------------+"
    db_connected "$db_name"
    echo "+--------------------------------------------------------------------------+"
    echo "| e.g. SELECT *; FROM table_name;                                          |"
    echo "|      SELECT column; FROM table_name;                                     |"
    echo "|      SELECT column ; FROM table_name ; WHERE column[==,<,>,>=,<=]value ; |"
    echo "|      SELECT * ; FROM table_name ; WHERE column[==,<,>,>=,<=]value ;      |"
    echo "|      SELECT column; FROM table_name;                                     |"
    echo "|      SELECT *; FROM table_name;                                          |"
    echo "+--------------------------------------------------------------------------+"
    echo "| 1 -  Back to DB Menu                                                     |"
    echo "| 2 -  Back to Main Menu                                                   |"
    echo "+--------------------------------------------------------------------------+"
    tput setaf 4 #change font color to blue
    read -p "$(tput setaf 3)Enter SQL Statement : " entry
    case $entry in
    1) exit ;;
    2) exit 2 ;;
    *) select_with_check ;;
    esac
done
