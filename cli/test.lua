-- A sample form of input table that can be fed to run.lua
-- this is somewhat the format that we want to dump
-- from the yang parser with some CLI dump option
return {
    set = {
         __container = 'set',
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
                priority = '',
                  __help_priority = 'internal ',
            },
            personal = {
                __container = 'personal';
                married = '',
                   __help_married = 'Marital status (yes/no)',
                age = '',
                   __help_age = 'How old? cmon tell me',
                address = '',
                   __help_address = 'where d"ya live?'
            },
        },
        system = {
                __container = 'system',
           hostname = '',
           location = '',
        }
    }
}
