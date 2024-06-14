"""
This file must be included after the instructions:
 - Using(Microgrids.jl)
 - Include ("../examples/data/Microgrid_Wind-Solar-H2_data.jl")
"""

"""
    Create a Microgrid of size `x`
    with x=[energy_rated_sto, power_rated_pv, power_rated_wind, power_rated_elyz, power_rated_fc, capacity_rated_hy_tank]
    You can also specify capex prices and initial filling rate of either Hydrogen tank or batteries.
    new_microgrid(x::Vector{Float64}= X,capex::Vector{Float64}=capex_def,initial_fill_rate::Vector{Float64})

"""

function new_microgrid(x::Vector{Float64}= X,capex::Vector{Float64}=capex_def,initial_fill_rate::Vector{Float64}=ini_filling_state)
    project = Project(lifetime, discount_rate, timestep, "€")
  gen = ProductionUnit(0.0,
      fuel_intercept, fuel_slope, fuel_price,
      capex[1], om_price_gen, lifetime_gen_y,lifetime_gen_h,
      load_ratio_min_gen, replacement_price_ratio,
      salvage_price_ratio, input_unit_gen,output_unit_gen)
  ftank = Tank(capacity_rated_ftank,capex[2], om_price_ftank,lifetime_ftank,loss_factor_ftank,initial_fill_rate[1],
          fuel_min_ratio, fuel_max_ratio,fuel_price, replacement_price_ratio, salvage_price_ratio)
  fuel_cell = ProductionUnit(x[5],cons_intercept_fc, cons_rate_fc,cons_price_fc,capex[3], om_price_fc,lifetime_fc_y,lifetime_fc_h,
              load_min_ratio_fc,replacement_price_ratio, salvage_price_ratio,input_unit_fc,output_unit_fc)
  hytank = Tank(x[6],capex[4], om_price_hytank,lifetime_hytank,loss_factor_hytank,initial_fill_rate[2],
              LoH_min_ratio, LoH_max_ratio,hy_price,replacement_price_ratio, salvage_price_ratio)
  dispatchables = DispatchableCompound{Float64}([gen], [fuel_cell])
     tanks = TankCompound{Float64}(ftank,hytank)

  elyz = ProductionUnit(x[4],cons_intercept_elyz,cons_slope_elyz,cons_price_elyz, capex[5], om_price_elyz, lifetime_elyz_y,lifetime_elyz_h,
  load_min_ratio_elyz,replacement_price_ratio, salvage_price_ratio,input_unit_elyz,output_unit_elyz)

  batt = Battery(x[1],
      capex[6], om_price_sto, lifetime_sto, lifetime_cycles,
      charge_rate, discharge_rate, loss_factor_sto, SoC_min, SoC_max,initial_fill_rate[3],
      replacement_price_ratio, salvage_price_ratio)
  pv = Photovoltaic(x[2], irradiance,
      capex[7], om_price_pv,
      lifetime_pv, derating_factor_pv,
      replacement_price_ratio, salvage_price_ratio)
  windgen = WindPower(x[3], cf_wind,
      capex[8], om_price_wind,
      lifetime_wind,
      replacement_price_ratio, salvage_price_ratio)
  
 mg = Microgrid(project, Pload,dispatchables,
  [elyz,],tanks,batt, [
      pv,
      windgen
      ])
  return mg
  end

"""
Simulate the performance of a Microgrid project 
Returns mg, traj, stats, costs
"""
    function simulate_microgrid(x=X,capex=capex_def,dispatch=dispatch_1)
     mg=new_microgrid(x)
    # Split decision variables (converted MW → kW):
    oper_traj = operation(mg, dispatch)
    if mg.tanks.h2Tank.capacity>0.0
        a = oper_traj.LoH[end]/mg.tanks.h2Tank.capacity
    else
        a=0.0
    end
   
    if mg.storage.energy_rated >0.0
         b = oper_traj.Ebatt[end]/mg.storage.energy_rated
    else
        b=0.0
    end
    
    ini=[0.0,a,b]
    mg=new_microgrid(x,capex,ini)
    # Launch simulation:
    traj, stats, costs = simulate(mg,dispatch)

    return  mg, traj ,stats, costs
end