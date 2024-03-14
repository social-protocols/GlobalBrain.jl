const t = BernoulliTally
@testset "Algorithm" begin

    # --- Discussion tree:
    # 1
    # |-2
    #   |-4
    #   |-5
    # |-3
    #   |-6
    #     |-7


    test_tree = TalliesTree(InMemoryTree(DetailedTally(707, 6, 6, 7, t(4, 18), t(7, 10), t(3, 15), t(8, 15)),[]))
    test_trees = [test_tree]

    # test_trees = [ 
    #   InMemoryTree(DetailedTally(707, nothing, nothing, 1, t(0, 0), t(0, 0), t(0, 0), t(20, 30)), [
    #     InMemoryTree(DetailedTally(707, 1, 1, 2, t(6, 16), t(8, 14), t(6, 9), t(7, 14)), [        
    #         InMemoryTree(DetailedTally(707, 2, 2, 4, t(7, 14), t(8, 9), t(0, 10), t(12, 12)),[])
    #         InMemoryTree(DetailedTally(707, 2, 2, 5, t(7, 14), t(5, 6), t(7, 13), t(5, 7)),[])
    #     ]),
    #     InMemoryTree(DetailedTally(707, 1, 1, 3, t(6, 16), t(9, 16), t(1, 13), t(8, 11)), [
    #         InMemoryTree(DetailedTally(707, 3, 3, 6, t(4, 8), t(5, 8), t(2, 3), t(3, 4)), [
    #            InMemoryTree(DetailedTally(707, 6, 6, 7, t(4, 18), t(7, 10), t(3, 15), t(8, 15)),[])
    #         ])
    #     ])
    #   ])
    # ];




    # # informed_tallies_generator = Base.Generator(identity, informed_tallies_vec)
    scores = score_tree(test_trees) do o
    end

end
