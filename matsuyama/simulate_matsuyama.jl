
#=

Code to simulate the model in Globalization and Synchronization of Innovation
Cycles by Kiminori Matsuyama, Laura Gardini and Iryna Sushko 

See <http://www.centreformacroeconomics.ac.uk/Discussion-Papers/2015/CFMDP2015-27-Paper.pdf>

=#

using PyPlot

"""
If we expand the implicit function for h_j(n_k) then we find that
it is a quadratic. We know that h_j(n_k) > 0 so we can get its
value by using the quadratic form
"""

function h_j(j::Int64, nk, s1::Float64, s2::Float64, theta::Float64, delta::Float64, rho::Float64)
    # Find out who's h we are evaluating
    if j == 1
        sj = s1
        sk = s2
    else
        sj = s2
        sk = s1
    end

    # Coefficients on the quadratic a x^2 + b x + c = 0
    a = 1.0
    b = ((rho + 1/rho)*nk - sj - sk)
    c = (nk*nk - (sj*nk)/rho - sk*rho*nk)

    # Positive solution of quadratic form
    root = (-b + sqrt(b*b - 4*a*c))/(2*a)

    return root
end

"Determine whether (n1, n2) is in the set DLL"
function DLL(n1::Float64, n2::Float64, s1_rho::Float64, s2_rho::Float64,
        s1::Float64, s2::Float64, theta::Float64, delta::Float64, rho::Float64)
    return (n1 <= s1_rho) && (n2 <= s2_rho)
end

"Determine whether (n1, n2) is in the set DHH"
function DHH(n1::Float64, n2::Float64, s1_rho::Float64, s2_rho::Float64,
        s1::Float64, s2::Float64, theta::Float64, delta::Float64, rho::Float64)
    return (n1 >= h_j(1, n2, s1, s2, theta, delta, rho)) && (n2 >= h_j(2, n1, s1, s2, theta, delta, rho))
end

"Determine whether (n1, n2) is in the set DHL"
function DHL(n1::Float64, n2::Float64, s1_rho::Float64, s2_rho::Float64,
        s1::Float64, s2::Float64, theta::Float64, delta::Float64, rho::Float64)
    return (n1 >= s1_rho) && (n2 <= h_j(2, n1, s1, s2, theta, delta, rho))
end

"Determine whether (n1, n2) is in the set DLH"
function DLH(n1::Float64, n2::Float64, s1_rho::Float64, s2_rho::Float64,
        s1::Float64, s2::Float64, theta::Float64, delta::Float64, rho::Float64)
    return (n1 <= h_j(1, n2, s1, s2, theta, delta, rho)) && (n2 >= s2_rho)
end

"""
Takes a current value for (n_{1, t}, n_{2, t}) and returns the
values (n_{1, t+1}, n_{2, t+1}) according to the law of motion.
"""
function one_step(n1::Float64, n2::Float64, s1_rho::Float64, s2_rho::Float64,
        s1::Float64, s2::Float64, theta::Float64, delta::Float64, rho::Float64)
    # Depending on where we are, evaluate the right branch
    if DLL(n1, n2, s1_rho, s2_rho, s1, s2, theta, delta, rho)
        n1_tp1 = delta*(theta*s1_rho + (1-theta)*n1)
        n2_tp1 = delta*(theta*s2_rho + (1-theta)*n2)
    elseif DHH(n1, n2, s1_rho, s2_rho, s1, s2, theta, delta, rho)
        n1_tp1 = delta*n1
        n2_tp1 = delta*n2
    elseif DHL(n1, n2, s1_rho, s2_rho, s1, s2, theta, delta, rho)
        n1_tp1 = delta*n1
        n2_tp1 = delta*(theta*h_j(2, n1, s1, s2, theta, delta, rho) + (1-theta)*n2)
    elseif DLH(n1, n2, s1_rho, s2_rho, s1, s2, theta, delta, rho)
        n1_tp1 = delta*(theta*h_j(1, n2, s1, s2, theta, delta, rho) + (1-theta)*n1)
        n2_tp1 = delta*n2
    end

    return n1_tp1, n2_tp1    
end

"""
Given an initial condition, continues to yield new values of
n1 and n2
"""
function new_n1n2(n1_0::Float64, n2_0::Float64, s1_rho::Float64, s2_rho::Float64,
        s1::Float64, s2::Float64, theta::Float64, delta::Float64, rho::Float64)
    n1_tp1, n2_tp1 = one_step(n1_0, n2_0, s1_rho, s2_rho, s1, s2, theta, delta, rho)
    return n1_tp1, n2_tp1
end

"""
Takes initial values and iterates forward to see whether
the histories eventually end up in sync.

If countries are symmetric then as soon as the two countries have the
same measure of firms then they will by synchronized -- However, if
they are not symmetric then it is possible they have the same measure
of firms but are not yet synchronized. To address this, we check whether
firms stay synchronized for `npers` periods with Euclidean norm

Parameters
----------
n1_0 : scalar(Float)
    Initial normalized measure of firms in country one
n2_0 : scalar(Float)
    Initial normalized measure of firms in country two
maxiter : scalar(Int)
    Maximum number of periods to simulate
npers : scalar(Int)
    Number of periods we would like the countries to have the
    same measure for

Returns
-------
synchronized : scalar(Bool)
    Did they two economies end up synchronized
pers_2_sync : scalar(Int)
    The number of periods required until they synchronized
"""
function pers_till_sync(n1_0::Float64, n2_0::Float64, s1_rho::Float64, s2_rho::Float64,
        s1::Float64, s2::Float64, theta::Float64, delta::Float64, rho::Float64,maxiter::Int64, npers)
    
    # Initialize the status of synchronization
    synchronized = false
    pers_2_sync = maxiter
    iters = 0
    
    nsync = 0

    while (~synchronized) && (iters < maxiter)
        # Increment the number of iterations and get next values
        iters += 1
        
        n1_t, n2_t = new_n1n2(n1_0, n2_0, s1_rho, s2_rho, s1, s2, theta, delta, rho)
        
        # Check whether same in this period
        if abs(n1_t - n2_t) < 1e-8
            nsync += 1
        # If not, then reset the nsync counter
        else
            nsync = 0
        end

        # If we have been in sync for npers then stop and countries
        # became synchronized nsync periods ago
        if nsync > npers
            synchronized = true
            pers_2_sync = iters - nsync
        end
        n1_0, n2_0 = n1_t, n2_t
    end
    return synchronized, pers_2_sync    
end

function create_attraction_basis(s1_rho, s2_rho, s1, s2, theta, delta, rho,
        maxiter, npers, npts)
    # Create unit range with npts
    synchronized, pers_2_sync = false, 0
    unit_range = linspace(0.0, 1.0, npts)

    # Allocate space to store time to sync
    time_2_sync = Array{Float64}(npts, npts)
    # Iterate over initial conditions
    for (i, n1_0) in enumerate(unit_range)
        for (j, n2_0) in enumerate(unit_range)
            #println((i,j))
            synchronized, pers_2_sync = pers_till_sync(n1_0, n2_0, s1_rho, s2_rho,
                                                        s1, s2, theta, delta, rho,
                                                        maxiter, npers)
            time_2_sync[i, j] = pers_2_sync
        end
    end    

    return time_2_sync
end             


# == Now we define a class for the model == #

"""
The paper "Globalization and Synchronization of Innovation Cycles" presents
a two country model with endogenous innovation cycles. Combines elements
from Deneckere Judd (1985) and Helpman Krugman (1985) to allow for a
model with trade that has firms who can introduce new varieties into
the economy.

We focus on being able to determine whether two countries eventually
synchronize their innovation cycles. To do this, we only need a few
of the many parameters. In particular, we need the parameters listed
below

Parameters
----------
s1 : scalar(Float)
    Amount of total labor in country 1 relative to total worldwide labor
theta : scalar(Float)
    A measure of how mcuh more of the competitive variety is used in
    production of final goods
delta : scalar(Float)
    Percentage of firms that are not exogenously destroyed every period
rho : scalar(Float)
    Measure of how expensive it is to trade between countries
"""
type MSGSync
    s1::Float64
    s2::Float64
    s1_rho::Float64
    s2_rho::Float64
    theta::Float64
    delta::Float64
    rho::Float64
end       
 
function MSGSync(s1::Float64=0.5, theta::Float64=2.5,
                 delta::Float64=0.7, rho::Float64=0.2)  
    # Store other cutoffs and parameters we use
    s2 = 1 - s1
    s1_rho = min((s1 - rho*s2) / (1 - rho),1) 
    s2_rho = 1 - s1_rho
    
    model=MSGSync(s1,s2,s1_rho,s2_rho,theta,delta,rho)
    
    return model
end
        
function unpack_params(model::MSGSync)
    return model.s1, model.s2, model.theta, model.delta, model.rho, model.s1_rho, model.s2_rho
end

"""
Simulates the values of (n1, n2) for T periods

Parameters
----------
n1_0 : scalar(Float)
Initial normalized measure of firms in country one
n2_0 : scalar(Float)
Initial normalized measure of firms in country two
T : scalar(Int)Number of periods to simulate

Returns
-------
n1 : Array{Float64}(ndim=1)
A history of normalized measures of firms in country one
n2 : Array{Float64}(ndim=1)
A history of normalized measures of firms in country two
"""
function simulate_n(model::MSGSync, n1_0::Float64, n2_0::Float64, T::Int64)
    # Unpack parameters
    s1, s2, theta, delta, rho, s1_rho, s2_rho = unpack_params(model)

    # Allocate space
    n1 = Array{Float64}(T)
    n2 = Array{Float64}(T)

    # Simulate for T periods
    for t in 1:T
        # Get next values
        n1[t], n2[t] = n1_0, n2_0
        n1_0, n2_0 = new_n1n2(n1_0, n2_0, s1_rho, s2_rho, s1, s2, theta, delta, rho)
    end

    return n1, n2
end

"""
Takes initial values and iterates forward to see whether
the histories eventually end up in sync.

If countries are symmetric then as soon as the two countries have the
same measure of firms then they will by synchronized -- However, if
they are not symmetric then it is possible they have the same measure
of firms but are not yet synchronized. To address this, we check whether
firms stay synchronized for `npers` periods with Euclidean norm
        
Parameters
----------
n1_0 : scalar(Float)
    Initial normalized measure of firms in country one
n2_0 : scalar(Float)
    Initial normalized measure of firms in country two
maxiter : scalar(Int)
    Maximum number of periods to simulate
npers : scalar(Int)
    Number of periods we would like the countries to have the
    same measure for

Returns
-------
synchronized : scalar(Bool)
    Did they two economies end up synchronized
pers_2_sync : scalar(Int)
    The number of periods required until they synchronized
"""
function pers_till_sync(model::MSGSync, n1_0::Float64, n2_0::Float64,
                        maxiter=500, npers=3)
    # Unpack parameters
    s1, s2, theta, delta, rho, s1_rho, s2_rho = unpack_params(model)
    
    return pers_till_sync(n1_0, n2_0, s1_rho, s2_rho, s1, s2, theta, delta, rho, maxiter, npers)
end

"""
Creates an attraction basis for values of n on [0, 1] X [0, 1] with npts in each dimension
"""    
function create_attraction_basis(model::MSGSync; maxiter=250, npers=3, npts=50)
    # Unpack parameters
    s1, s2, theta, delta, rho, s1_rho, s2_rho = unpack_params(model)

    ab = create_attraction_basis(s1_rho, s2_rho, s1, s2, theta, delta,
                                  rho, maxiter, npers, npts)
    return ab
end
