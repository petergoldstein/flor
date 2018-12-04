
#
# specifying flor
#
# Wed Jun 27 13:27:56 JST 2018
#

require 'spec_helper'


describe 'Flor procedures' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe '_ref' do

    it 'returns the referenced values' do

      r = @executor.launch(
        %q{
          _ref
            'f'
            'o'
            [ 'a', 'b' ]
            'c'
        },
        payload: {
          'o' => { 'a' => { 'c' => 'C0' }, 'b' => { 'c' => 'C1' } } })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq([ 'C0', 'C1' ])
    end

    it 'looks up variables' do

      r = @executor.launch(
        %q{
          _ref
            'v'
            'a'
            1
        },
        variables: {
          'a' => [ 'A', 'B', 'C' ] })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq('B')
    end

    it 'gives a helpful error message when not finding "deep"' do

      r = @executor.launch(
        %q{
          #set a 1
          a.age
        },
        variables: { 'a' => 1 })

      expect(r['point']).to eq('failed')

      expect(r['error']['kla']
        ).to eq('IndexError')
      expect(r['error']['msg']
        ).to eq('variable at "a" is a number, it has no key "age"')
    end
  end

  describe '_rep' do

    it 'returns a path' do

      r = @executor.launch(
        %q{
          _rep
            'f'
            'o'
            [ 'a', 'b' ]
            'c'
        },
        payload: {
          'o' => { 'a' => { 'c' => 'C0' }, 'b' => { 'c' => 'C1' } } })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq([ 'f', 'o', %w[ a b ], 'c' ])
    end
  end
end

