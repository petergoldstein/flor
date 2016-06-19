
#
# specifying flor
#
# Sat Jun 18 16:43:30 JST 2016
#

require 'spec_helper'


describe Flor::Loader do

  before :each do

    unit =
      OpenStruct.new(conf: {
        'lod_path' => File.dirname(__FILE__) + '/loader/'
      })
    @loader = Flor::Loader.new(unit)
  end

  # spec/unit/loader
  # ├── etc
  # │   └── variables
  # │       ├── dot.json
  # │       ├── net.example.json
  # │       └── net.json
  # ├── lib
  # │   ├── flows
  # │   │   ├── net.example
  # │   │   │   └── flow0.flon
  # │   │   └── org.example
  # │   │       └── flow0.flon
  # │   └── taskers
  # │       ├── alice
  # │       │   └── dot.json
  # │       ├── net.example
  # │       │   └── .gitkeep
  # │       └── org.example
  # │           ├── alice
  # │           │   └── dot.json
  # │           └── bob
  # │               └── dot.json
  # └── usr
  #     ├── net.example
  #     │   ├── etc
  #     │   │   └── variables
  #     │   │       └── dot.json
  #     │   └── lib
  #     │       ├── flows
  #     │       │   └── flow1.flon
  #     │       └── taskers
  #     │           └── bob
  #     │               └── dot.json
  #     └── org.example
  #         ├── etc
  #         │   └── variables
  #         │       └── dot.json
  #         └── lib
  #             ├── flows
  #             │   └── flow1.flon
  #             └── taskers
  #                 └── .gitkeep

  describe '#variables' do

    it 'loads variables' do

      net = @loader.variables('net')
      net_example = @loader.variables('net.example')
      org_example = @loader.variables('org.example')

      expect(net['car']).to eq('fiat')
      expect(net_example['car']).to eq('alfa romeo')
      expect(org_example['car']).to eq(nil)
      expect(net_example['flower']).to eq('rose')
      expect(org_example['flower']).to eq('lilly')
    end
  end

  describe '#split' do

    it 'splits domains' do

      expect(
        @loader.send(:split, 'org.example.x.y.z')
      ).to eq([
        [ 'org', 'example.x.y.z' ],
        [ 'org.example', 'x.y.z' ],
        [ 'org.example.x', 'y.z' ],
        [ 'org.example.x.y', 'z' ],
        [ 'org.example.x.y.z', nil ]
      ])
    end
  end
end

