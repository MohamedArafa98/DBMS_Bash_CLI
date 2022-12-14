#! /bin/bash
# Style the Connected Line

function db_connected() {
	db_name=$1
	typeset -i filler_length
	filler_length=(54-${#db_name})
	echo -n "| $(tput setaf 3)<$1 "
	for ((counter = 0; counter < filler_length; counter++)); do echo -n "-"; done
	echo " Connected>$(tput setaf 4) |" #change font color to Blue
}
function insert_with_check() {
	#Strip input from all SQL words.
	sql_line=$(echo "$entry" | sed -e 's/INSERT//g' -e 's/INTO//g' -e 's/VALUES//g' | sed -e 's/insert//g' -e 's/into//g' -e 's/values//g')

	#get table and check its existance
	table_name=$(echo "$sql_line" | awk -F';' '{gsub(/^[ \t]+|[ \t]+$/, "",$1);print $1}')
	if [[ ! -f "$table_name" ]]; 
		then
		echo "Error : Invalid Table Name"
		return
	fi

	#table columns number
	table_columns_number=$(awk -F'|' '{if(NR==1){print NF}}' "$table_name")

	#get insert columns number
	insert_columns_number=$(echo "$sql_line" | awk -F',' 'END{print NF}')

	#Check if the number of values matches the number of table columns
	if ((insert_columns_number != table_columns_number)); 
		then
		echo "Error : Invalid Columns Number, Must Be $table_columns_number Values"
		return
	fi

	#Form the Record

	record=""

	for ((i = 1; i <= $insert_columns_number; i++)); do

		#Strip the input from all special characters and 
		#Check if the entered value matchs the column metadata
		value=$(echo "$sql_line"| awk -F';' '{print $2}'| sed -e 's/(//g' -e 's/)//g' |
		awk -F',' '{gsub(/^[ \t]+|[ \t]+$/, "",$'$i');print $'$i'}')
		
		#Check if the entered value matchs the datatype
		col_data_type=$(awk -F'|' '{if (NR=="'$i'") { print $2}}' ".$table_name")
		
		#Check if there is a PK
		is_pk=$(awk -F'|' '{if (NR=="'$i'") { print $3}}' ".$table_name")

		#Check if the entered value matchs the datatype and if not print invalid
		case $value in
			[a-zA-Z]*) if ((col_data_type != "txt")); then echo "Error : Invalid Value Data Type"; return; fi ;;
			[0-9]*) if ((col_data_type != "int")); then echo "Error : Invalid Value Data Type" return; fi ;;
			*) echo "Error : Invalid Value";return	;;
		esac

		#Check if there is a PK an if the value exists then print invalid
		if ((is_pk == "pk")); then
			value_exist=$(awk -v new_value="$value" -F'|' 'BEGIN{found=0} {if(NR!=1){if($"'$i'"==new_value)found=1}} END{print found}' "$table_name")
			if ((value_exist == 1)); then echo "Error : Primary Key Exist"; return; fi
		fi
		
		#Insert the value under it's column
		record=$(echo "$record" | awk -v value="$value" -F'|' '{OFS=FS}{$"'$i'"=value; print}')

	done

	#Append the Record1
	echo "$record" >>"$table_name"
	echo "Inserted Successfully"
}

clear
db_name=$1
while true; do
	tput setaf 4 #change font color to Blue
	echo "+---------------------------------------------------------------------+"
	db_connected "$db_name"
	echo "+---------------------------------------------------------------------+"
	echo "| e.g. INSERT INTO table_name ; VALUES(value1, value2 . . . )         |"
	echo "+---------------------------------------------------------------------+"
	echo "| 1 -  Back to DB Menu                                                |"
	echo "| 2 -  Back to Main Menu                                              |"
	echo "+---------------------------------------------------------------------+"
	tput setaf 4 #change font color to Yellow
	read -p "$(tput setaf 3)Enter SQL Delete Statement : " entry
	case $entry in
	1) exit ;;
	2) exit 2 ;;
	*) insert_with_check ;;
	esac
done