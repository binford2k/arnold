Puppet::Parser::Functions::newfunction(:arnold, :doc => "Loads parameters and include classes from Arnold") do
  function_arnold_params
  function_arnold_include
end
