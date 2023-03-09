# Testing the WQP functions

@testset "WQP Testing" begin

    # the sites query
    df, response = whatWQPsites(lat="44.2", long="-88.9", within="2.5")
    @test size(df) == (4, 37)  # matches Python output for same command

end