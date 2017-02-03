-- A sample form of input table that can be fed to run.lua
-- this is somewhat the format that we want to dump
-- from the yang parser with some CLI dump option
return {
    set = {
         __is_container = true
        employee = {
            __key = 'name', -- this is to skip the field (next)
            name = '',
               __help_name = 'Employee name', -- Must gen if not - cli cant show "Required" msg
            grade = '',
               __help_grade = 'Grade',
            salary = '',
               __help_salary = 'Salary (CTC)',
            projects = {
                __key = 'name',
                name = '',
                   __help_name = 'Project code',
                duration = '',
                  __help_duration = 'Project duration',
                customer = '',
                  __help_customer = 'for cust',
            },
            personal = {
                __is_container = true;
                married = '',
                   __help_married = 'Marital status (yes/no)',
                age = '',
            },
        },
        system = {
                __is_container = true;
           hostname = '',
           location = '',
        }
    }
}
